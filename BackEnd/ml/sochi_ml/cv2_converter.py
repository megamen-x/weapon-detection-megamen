import cv2
import numpy


def crop(path_to_image: str, yolo_predict) -> numpy.ndarray:
    """
    Get the original image and return cropped image (bbox from yolo v8)
    :param path_to_image: str
    :param yolo_predict: yolo v8 results
    :return: array for cropped image
    """
    image = cv2.imread(path_to_image)
    height, width, _ = image.shape
    try:
        x_min, y_min, x_max, y_max = yolo_predict[0].boxes.xyxyn[0]
        x_min = int(x_min * width)
        y_min = int(y_min * height)
        x_max = int(x_max * width)
        y_max = int(y_max * height)

        w = x_max - x_min
        h = y_max - y_min

        crop_img = yolo_predict[0].orig_img[y_min:y_min + h, x_min:x_min + w]  # np.array
        return crop_img
    except:
        return None


def draw_boxes(path_to_image: str, yolo_predict) -> numpy.ndarray:
    """
    Get the original image and return image with visualized bboxes (coord from yolo v8 predict)
    :param path_to_image: str
    :param yolo_predict: yolo v8 results
    :return: array with visualized bboxes
    """
    image = cv2.imread(path_to_image)
    height, width, _ = image.shape

    x_min, y_min, x_max, y_max = yolo_predict[0].boxes.xyxyn[0]
    x_min = int(x_min * width)
    y_min = int(y_min * height)
    x_max = int(x_max * width)
    y_max = int(y_max * height)
    cv2.rectangle(image, (x_min, y_min), (x_max, y_max), (0, 255, 0), 5) # array here
    return image
