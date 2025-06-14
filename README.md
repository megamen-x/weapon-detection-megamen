<a name="readme-top"></a>  

<div align="center">

  <h1 align="center">Команда Megamen</h1>

  <p align="center">
    <h3>Репозиторий для хакатона «Цифровой прорыв. Сезон: Искусственный интеллект»
    <br />
    <br />
    Кейс от Министерства внутренних дел Российской федерации - «Распознавание образа огнестрельного оружия».<h3>
    <br />
    <a href="https://github.com/mireaMegaman/perm_hack/issues">Сообщить об ошибке</a>
    ·
    <a href="https://github.com/mireaMegaman/perm_hack/issues">Предложить улучшение</a>
  </p>
</div>

**Содержание:**
1. [Проблематика кейсодержателя](#title1)
2. [Описание решения](#title2)
3. [Развертка приложения](#title3)
4. [Демонстрация работы](#title4)
5. [Награды](#title5)


## <a id="title1">Часть 1. Проблематика кейсодержателя</a>
Задание от Министерства внутренних дел Российской Федерации состояло в следующем: 
было необходимо **создать приложения для распознавания образа огнестрельного оружия на фотографии и видео**.

Приложение может использоваться для:
* содействия оперативной работе специальных служб;
* обеспечения безопасности, особенно в зонах повышенной опасности.

Важными особенностями при обучении модели команда выделяет:
* повышение разрешения фотографии (при необходимости);
* точное определение оружия (или его силуэта) на фотографии.


<p align="right">(<a href="#readme-top"><i>Вернуться наверх</i></a>)</p>

## <a id="title2">Часть 2. Краткое описание решения</a>

**Используемый стек технологий:**
![изображение](https://github.com/mireaMegaman/perm_hack/blob/main/readme_assets/stack.png)

**Общая схема решения:**
![изображение](https://github.com/mireaMegaman/perm_hack/blob/main/readme_assets/solution.png)


**В качестве моделей мы предлагаем::**
1. Ансамбль из двух моделей RT-DETR — занимается обнаружением только оружия (модели размечены и обучены на 2 класса — ```short_weapon``` и ```long_weapon```);
2. Ансамбль из YOLO v8 и RT-DETR — занимается обнаружением как оружия, так и разметкой людей (помимо классов ```short_weapon``` и ```long_weapon```, YOLO v8 размечена на 2 дополнительных класса — ```man_with_weapons``` и ```man_without_weapons```);

По умолчанию, в нашем решении предоставлен **второй вариант** — однако, приложение может быть пересобрано и под разметку исключительно оружия. 

На изображениях ниже вы можете видеть приблизительную схему предсказания моделей в нашем решении.
![изображение](https://github.com/mireaMegaman/perm_hack/blob/main/readme_assets/Yolo_RTDETR.png)
![изображение](https://github.com/mireaMegaman/perm_hack/blob/main/readme_assets/RTDERT.png)

**Для демонстрационного приложения были выбраны:**
*  Flutter - для сборки мультиплатформенного приложения, с возможностью **развития** из десктопного варианта и в мобильную среду разработки;

*  FastAPI - в качестве внутренней серверной части, для обеспечения быстрого и эффективного взаимодействия ML моделей с приложением;


**Развитие и масштабируемость:**
В оформлении.


<p align="right">(<a href="#readme-top"><i>Вернуться наверх</i></a>)</p>

## <a id="title3">Часть 3. Развертка приложения</a>

**Запуск приложения на устройстве с Windows или Linux**
Благодаря Flutter существует возможность собрать финальное приложение на разные платформы заранее. 
Таким образом, для быстрого тестирования можно запустить собранное приложение по следующей инструкции. <br>

После того, как вы скопировали себе на устройство наш репозиторий - нужно выполнить два простых шага: <br>
1. Для корректной работы BackEnd части (модели, FastAPI) укажите в терминале команду ```docker run -p 80:80 georgechufff/hacks_ai_perm:1.0.2```.<br>
2. Далее:<br>
* На Windows: перейдите в [аналогичную директорию](https://github.com/mireaMegaman/perm_hack/blob/main/mmt_fl/build/windows/runner/Debug/mmt_fl.exe)
на вашем устройстве и запустите файл ```mmt_fl.exe```.  <br>
* На Linux: перейдите в [аналогичную директорию](https://github.com/mireaMegaman/perm_hack/blob/main/mmt_fl/build/linux/x64/debug/bundle/mmt_fl)
на вашем устройстве и запустите файл ```mmt_fl```.  <br>

<h3> </h3>

**Развертка приложения на Flutter.**
Если же вы хотите посмотреть на приложение в debug-режиме:
```
$ git clone -b beta https://github.com/flutter/flutter.git
```
в конец файла ```~/.bashrc``` добавить 
```
export PATH=<путь к каталогу>/flutter/bin:$PATH
export ANDROID_HOME=/<путь к каталогу>/android-sdk-linux
export PATH=${PATH}:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```
и проверить правильность установки с помощью
```
$ flutter doctor
```

Для запуска приложения - перейдите к файлу ```./mmt_fl/lib/main.dart``` и запустите его в режиме ```Run and Debug```

**Развертка FastApi-сервера:**

Альтернативный способ запуск FastAPI на локальном хосте (для проверки моделей, без приложения):
В Visual Studio Code (Windows) через терминал последовательно выполнить следующие команды:
```
python -m venv venv
venv/Scripts/activate
```
```
cd BackEnd
pip install -r requirements.txt
```
После установки зависимостей:
```
cd ..
uvicorn BackEnd.main:app
```

<p align="right">(<a href="#readme-top"><i>Вернуться наверх</i></a>)</p>

## <a id="title4">Часть 4. Демонстрация работы решения</a>

Ознакомиться с подробным роликом тестирования приложения можно на нашем канале: https://www.youtube.com/channel/UC5qC_I5o2aatXDSxTHbjxzg

<p align="right">(<a href="#readme-top"><i>Вернуться наверх</i></a>)</p>

## <a id="title5">Часть 5. Награды</a>

<div style="display: flex; justify-content: space-between;">
  <img src="https://github.com/megamen-x/weapon-detection-megamen/blob/main/readme_assets/PFO_Egor.png" alt="Image 1" style="width: 23%; height: auto; margin: 0 1%;">
  <img src="https://github.com/megamen-x/weapon-detection-megamen/blob/main/readme_assets/PFO_Lesha.png" alt="Image 2" style="width: 23%; height: auto; margin: 0 1%;">
  <img src="https://github.com/megamen-x/weapon-detection-megamen/blob/main/readme_assets/PFO_Sasha.png" alt="Image 3" style="width: 23%; height: auto; margin: 0 1%;">
  <img src="https://github.com/megamen-x/weapon-detection-megamen/blob/main/readme_assets/PFO_Vlad.png" alt="Image 4" style="width: 23%; height: auto; margin: 0 1%;">
</div>

<p align="right">(<a href="#readme-top"><i>Вернуться наверх</i></a>)</p>
