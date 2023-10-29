from ultralytics import YOLO
import cv2
from helper import create_video_writer
import datetime


def tracking(video_cap, model):
    video_cap = cv2.VideoCapture("2.mp4")
    writer = create_video_writer(video_cap, "output.mp4")

    while True:
        start = datetime.datetime.now()
        ret, frame = video_cap.read()

        if not ret:
            break

        detections = model(frame)[0]
        for data in detections.boxes.data.tolist():
            confidence = data[4]

            if float(confidence) < 0.3:
                continue

            xmin, ymin, xmax, ymax = int(data[0]), int(data[1]), int(data[2]), int(data[3])
            cv2.rectangle(frame, (xmin, ymin), (xmax, ymax), (255, 0, 0), 2)

        end = datetime.datetime.now()
        total = (end - start).total_seconds()
        print(f"Time to process 1 frame: {total * 1000:.0f} milliseconds")

        fps = f"FPS: {1 / total:.2f}"
        cv2.putText(frame, fps, (50, 50),
                    cv2.FONT_HERSHEY_SIMPLEX, 2, (0, 0, 255), 8)

        cv2.imshow("Frame", frame)
        writer.write(frame)
        if cv2.waitKey(1) == ord("q"):
            break

    video_cap.release()
    writer.release()
    cv2.destroyAllWindows()
