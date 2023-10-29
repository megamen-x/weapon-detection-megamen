import io
import os
import sys
import base64

parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__)))
sochi_ml = parent_dir + '/ml/sochi_ml/'
ml = parent_dir + '/ml/'
sys.path.insert(0, sochi_ml)
print(ml + 'best_large.pt')
from cv2_converter import draw_boxes_from_list
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

from ultralytics import YOLO, RTDETR
from PIL import Image
import torch.nn.functional as F


models = None
weights = [1, 1.3]

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
    # model_1 = YOLO(os.path.join('BackEnd', 'ml', 'best_large.pt')) # впиши сюда путь до первой модели
    # model_2 = YOLO(os.path.join('BackEnd', 'ml', 'best_model_from_datasphere.pt')) # впиши сюда путь для второй модели
    model_1 = YOLO(ml + 'best_model_from_datasphere.pt') # впиши сюда путь до первой модели
    model_2 = RTDETR(ml + 'best_rt_detr.pt')
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
    path_files = parent_dir + '/photos/'
    images = file.files
    names = file.files_names
    json_ans = {"data": []}
    for i, file in enumerate(images):
        image_as_bytes = str.encode(file)  # convert string to bytes
        img_recovered = base64.b64decode(image_as_bytes)  # decode base64string
        image = Image.open(io.BytesIO(img_recovered))
        base_file_path = parent_dir + '/original/' + f'{names[i]}'
        _ = image.save(base_file_path)
        boxes, scores, labels = ensemble_boxes(
            models=models,
            path_to_image=base_file_path,
            weights=weights
        )
        count_labels = count_classes(labels)
        bbox_image = draw_boxes_from_list(
            image_path1=base_file_path,
            boxes_1=boxes,
            labels1=labels
        )
        imwrite(os.path.join(path_files, f"boxed_image-{names[i]}"), bbox_image)
        count_short, count_long, count_dangerous_people = count_labels['4'], count_labels['1'], count_labels['2']
        json_ans['data'].append({'name': names[i], 'count_short': count_short, 'count_long' : count_long, 'count_dangerous_people': count_dangerous_people})
    with open(path_files + 'data.txt', 'w') as outfile:
        json.dump(json_ans, outfile)
    background.add_task(remove_file, path_files)
    return to_zip(path_files)


@app.post('/video')
def video_traking(input: Video):
    # results = yolo.track(input.file)
    return to_zip('D:/Work/hack_perm_megamen/perm_hack/BackEnd/video')
    