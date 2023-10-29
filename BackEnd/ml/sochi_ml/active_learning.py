from ultralytics import YOLO, RTDETR
from typing import Union, List


def freeze_layer(trainer, num_freeze: int):
    """
    Функция заморозки всех слоев модели, кроме num_freeze последних
    """
    model = trainer.model
    freeze = [f'model.{x}.' for x in range(num_freeze)]
    for k, v in model.named_parameters():
        v.requires_grad = True
        if any(x in k for x in freeze):
            print(f'freezing {k}')
            v.requires_grad = False


def wandb_logger():
    """
    Тут должен быть локальный запуск wandb
    """
    pass


def train(
        model: Union[YOLO, RTDETR],
        path_to_config: str,
        device: Union[str, List[int]],
        logging_type: str = 'wandb',
        is_freeze: bool = False,
        num_freeze: int = 10,
        epochs: int = 10,
        batch_size: int = -1
):
    if logging_type == 'wandb':
        wandb_logger()

    elif logging_type not in ['wandb', 'None']:
        raise NotImplementedError(f"{logging_type} if not implemented yet. Supported types: ['wandb', 'None'].")

    if is_freeze:
        assert num_freeze > 0, "Num layers for freezing must be more than zero."
        model.add_callback("on_train_start", freeze_layer)

    model.train(
        data=path_to_config,
        epochs=epochs,
        device=device,
        batch=batch_size,
        imgsz=640,
        resume=True,
        seed=42
    )  # resume=True для возобновления обучения с последними сохраненными состояниями оптимизатора и модели
