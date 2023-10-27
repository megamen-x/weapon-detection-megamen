import io
import os
import sys
import base64
sys.path.append('BackEnd\\ml')
sys.path.append('BackEnd\\ml\\sochi_ml')
from ocr_module import generate_proba, is_proper
from cv2_converter import crop, draw_boxes

from time import sleep
from typing import List
from cv2 import imwrite

from zipfile import ZipFile, ZIP_DEFLATED
import json
from pydantic import BaseModel
from fastapi import BackgroundTasks, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse

from ultralytics import YOLO
from PIL import Image
import torch.nn.functional as F

from transformers import (
    TrOCRProcessor,
    VisionEncoderDecoderModel
)


yolo = None
ocr = None

app = FastAPI(title="Recognition of railway car numbers")

class Image64(BaseModel):
    files: List[str]
    files_names: List[str]

origins = [
    "*",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*",],
    allow_headers=["*",],
)


@app.on_event("startup")
def startup_event():
    global yolo, processor, ocr_model
    yolo = YOLO(os.path.join('BackEnd', 'ml', 'best.pt'))
    processor = TrOCRProcessor.from_pretrained('BackEnd\\ml\\processor')
    ocr_model = VisionEncoderDecoderModel.from_pretrained('BackEnd\\ml\\tr_ocr_m')


def to_zip(path: str):
    zip_io = io.BytesIO()
    with ZipFile(zip_io, mode='w', compression=ZIP_DEFLATED) as temp_zip:
        for root, _, files in os.walk(path):
            for fileName in files:
                temp_zip.write(os.path.join(root, fileName), fileName) # первый параметр отвечает за то, какой файл выбрать, а второй, как он будет называться
    return StreamingResponse(
        iter([zip_io.getvalue()]), 
        media_type="application/x-zip-compressed", 
        headers = { "Content-Disposition": f"attachment; filename=images.zip"}
    )


def remove_file(path: str) -> None:
    sleep(10)
    for f in os.listdir(path):
        os.remove(os.path.join(path, f))


def postprocessing(value: str):
    try:
        _ = int(value)
        return value
    except:
        value = value.lower()
        value = value.replace(' ', '')
        value = value.replace('g', '6')
        value = value.replace('i', '1')
        value = value.replace('e', '9')
        value = value.replace('/', '7')
        value = value.replace('|', '1')
        answer = ''
        for el in value:
            if el.isdigit():
                answer += el
        return answer


def recognize(base_path: str):
    image = Image.open(base_path).convert("RGB")
    pixel_values = processor(images=image, return_tensors="pt").pixel_values
    generated_ids = ocr_model.generate(
        pixel_values,
        output_scores=True,
        return_dict_in_generate=True
    )
    ids, scores = generated_ids['sequences'], generated_ids['scores']
    generated_text = processor.batch_decode(ids, skip_special_tokens=True)[0]  # лейбл
    generated_text = postprocessing(generated_text)
    _, probabilities = generate_proba(scores, ids, processor)  # вероятности 
    is_correct = is_proper(generated_text)
    return probabilities, generated_text, is_correct


@app.post('/get_result_64')
def main_64(file: Image64, background: BackgroundTasks):
    path_files = os.path.join('BackEnd', 'photos')
    images = file.files
    names = file.files_names
    json_ans = {"data": []}
    for i, file in enumerate(images):
        image_as_bytes = str.encode(file)  # convert string to bytes
        img_recovered = base64.b64decode(image_as_bytes)  # decode base64string
        image = Image.open(io.BytesIO(img_recovered))
        base_file_path = os.path.join(path_files, names[i])
        _ = image.save(base_file_path)
        results = yolo.predict(image)
        cropped_image = crop(base_file_path, results)
        if cropped_image is None:
            # json_ans['data'].append({'name' : names[i], 'number': "Не удалось распознать номер"})
            json_ans['data'].append({'name' : names[i], 'number': "Ошибка", 'confidence': 'Не удалось распознать номер' , 'is_correct' : 'Необходимо участие оператора'})
        else:
            imwrite(os.path.join(path_files, f"cropped_image-{names[i]}"), cropped_image)
            imwrite(os.path.join(path_files, f"cropped_image-{names[i]}"), cropped_image)
            bbox_image = draw_boxes(base_file_path, results)
            imwrite(os.path.join(path_files, f"boxed_image-{names[i]}"), bbox_image)
            probability, number, is_correct = recognize(os.path.join(path_files, f"cropped_image-{names[i]}"))
            json_ans['data'].append({'name' : names[i], 'number': number, 'confidence': 'Оператор не требуется' if float(probability) > 0.5 else 'Требует внимания оператора', 'is_correct' : 'Подтверждена' if is_correct else 'Ошибка!'})
    with open(os.path.join(path_files, 'data.txt'), 'w') as outfile:
        json.dump(json_ans, outfile)
    background.add_task(remove_file, path_files)
    return to_zip(path_files)
