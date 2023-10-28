import torch
from ensemble_boxes import *
from ultralytics import YOLO
from typing import List, Optional, Dict
from cv2_converter import draw_boxes_from_list
import cv2
import os

device = 'cuda' if torch.cuda.is_available() else 'cpu'


def restructure_preds(yolo_pred):
    """
    Формирует предскзаания моделей в необходимом формате:
    [координаты bbox, уверенность в предсказаниях, предсказанные лейблы]
    :param yolo_pred: возвращаемое значение функции predict_one_model, содержит всю информацию о предсказании моделью
    :return:
    """
    boxes_list, scores_list, labels_list = list(), list(), list()

    for object_ in yolo_pred[0].boxes:
        boxes_list.extend(object_.xyxyn.tolist())
        scores_list.extend(object_.conf.tolist())
        labels_list.extend(object_.cls.tolist())

    return boxes_list, scores_list, labels_list


def ensemble_boxes(
        models: List[YOLO],
        path_to_image: str,
        weights: Optional[List[float]] = None,
        run_type: str = 'wbf',
        iou_thr: float = 0.5,
        skip_box_thr: float = 0.0001,
        sigma: float = 0.1
):
    """
    Данная функция усредняет предсказания модели по боксам, исходя из ряда параметров
    param models: массив моделей, которые будут делать предсказание
    param path_to_image: путь до изображения для предсказания
    param weights: значимость каждой модели в ансамбле
    param run_type: тип усреднения
    param iou_thr: значение iou в совпадении полей
    param skip_box_thr: минимальная уверенность модели в предсказании
    param sigma:
    """
    if weights is None:
        weights = [1 for _ in range(len(models))]

    boxes_, scores_, labels_ = [], [], []
    for model in models:
        yolo_model_predict = model.predict(path_to_image, save_conf=True)
        boxes_list, scores_list, labels_list = restructure_preds(yolo_model_predict)

        boxes_.append(boxes_list)
        scores_.append(scores_list)
        labels_.append(labels_list)

    if run_type == 'wbf':
        boxes, scores, labels = weighted_boxes_fusion(
            boxes_,
            scores_,
            labels_,
            weights=weights,
            iou_thr=iou_thr,
            skip_box_thr=skip_box_thr
        )

    elif run_type == 'soft_nms':
        boxes, scores, labels = soft_nms(
            boxes_,
            scores_,
            labels_,
            weights=weights,
            iou_thr=iou_thr,
            sigma=sigma,
            thresh=skip_box_thr
        )

    elif run_type == 'nms':
        boxes, scores, labels = nms(
            boxes_,
            scores_,
            labels_,
            weights=weights,
            iou_thr=iou_thr
        )

    elif run_type == 'non_maximum_weighted':
        boxes, scores, labels = non_maximum_weighted(
            boxes_,
            scores_,
            labels_,
            weights=weights,
            iou_thr=iou_thr,
            skip_box_thr=skip_box_thr
        )

    else:
        raise NotImplementedError(f"{run_type} type method for ensembling boxes is not implemented. Available "
                                  f"methods: ['nms', 'soft_nms', 'non_maximum_weighted', 'wbf']")

    return boxes, scores, labels


def count_classes(labels: List[int]) -> Dict[str, int]:
    ans = {
        '1': 0,
        '2': 0,
        '3': 0,
        '4': 0
    }

    for label in labels:
        ans[str(int(label))] += 1

    return ans


if __name__ == '__main__':
    model_1 = YOLO('/home/agar1us/Documents/perm_hack/BackEnd/ml/best_large.pt') # впиши сюда путь до первой модели
    model_2 = YOLO('/home/agar1us/Documents/perm_hack/BackEnd/ml/best_model_from_datasphere.pt') # впиши сюда путь для второй модели

    models = [model_1, model_2]

    path_to_image = '/home/agar1us/Documents/perm_hack/4c45ef8a-frame_11_339_png.rf.3b720327f28c092e000e6d76162e3091.jpg'
    boxes, scores, labels = ensemble_boxes(
            models=models,
            path_to_image=path_to_image
        )
    print(labels)
    count_labels = count_classes(labels)
    bbox_image = draw_boxes_from_list(
        path_to_image=path_to_image,
        list_yolo_pred=boxes,
        labels=labels
    )
    cv2.imwrite(os.path.join("/home/agar1us/Documents/perm_hack/BackEnd/photos", "boxed_image-test.jpg"), bbox_image)
