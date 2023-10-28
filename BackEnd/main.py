import io
import os
import sys
import base64
sys.path.append(os.path.join('BackEnd', 'ml'))
sys.path.append(os.path.join('BackEnd', 'ml', 'sochi_ml'))
from cv2_converter import crop, draw_boxes, draw_boxes_from_list
from ensemble import ensemble_boxes, count_classes

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


models = None

app = FastAPI(title="Guns detection")

class Image64(BaseModel):
    files: List[str]
    files_names: List[str]


class Video(BaseModel):
    file: str


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
    global models
    model_1 = YOLO(os.path.join('BackEnd', 'ml', 'best_large.pt')) # впиши сюда путь до первой модели
    model_2 = YOLO(os.path.join('BackEnd', 'ml', 'best_large_from_datasphere.pt')) # впиши сюда путь для второй модели
    models = [model_1, model_2]


def to_zip(path: str):
    zip_io = io.BytesIO()
    with ZipFile(zip_io, mode='w', compression=ZIP_DEFLATED) as temp_zip:
        for root, _, files in os.walk(path):
            for fileName in files:
                temp_zip.write(os.path.join(root, fileName), fileName) # первый параметр отвечает за то, какой файл выбрать, а второй, как он будет называться
    return StreamingResponse(
        iter([zip_io.getvalue()]), 
        media_type="application/x-zip-compressed", 
        headers = { "Content-Disposition": f"attachment; filename=results.zip"}
    )


def remove_file(path: str) -> None:
    sleep(10)
    for f in os.listdir(path):
        os.remove(os.path.join(path, f))


def full_predict():
    return 1, 1, 2


@app.post('/get_result_64')
def image_detection(file: Image64, background: BackgroundTasks):
    path_files = os.path.join('BackEnd', 'photos')
    images = file.files
    names = file.files_names
    json_ans = {"data": []}
    for i, file in enumerate(images):
        image_as_bytes = str.encode(file)  # convert string to bytes
        img_recovered = base64.b64decode(image_as_bytes)  # decode base64string
        image = Image.open(io.BytesIO(img_recovered))
        base_file_path = os.path.join('BackEnd', 'original', names[i])
        _ = image.save(base_file_path)
        # results = yolo.predict(image)
        boxes, scores, labels = ensemble_boxes(
            models=models,
            path_to_image=base_file_path
        )
        count_labels = count_classes(labels)
        bbox_image = draw_boxes_from_list(
            path_to_image=base_file_path,
            list_yolo_pred=boxes
        )
        
        # bbox_image = draw_boxes(base_file_path, results)
        imwrite(os.path.join(path_files, f"boxed_image-{names[i]}"), bbox_image)
        count_short, count_long = count_labels['1'], count_labels['0']
        json_ans['data'].append({'name': names[i], 'count_short': count_short, 'count_long' : count_long})
    with open(os.path.join(path_files, 'data.txt'), 'w') as outfile:
        json.dump(json_ans, outfile)
    background.add_task(remove_file, path_files)
    return to_zip(path_files)


@app.post('/video')
def video_traking(input: Video):
    # results = yolo.track(input.file)
    return to_zip('/home/agar1us/Documents/perm_hack/video')