import os

from flask import Flask

app = Flask(__name__)


@app.get("/")
def index():
    name = os.getenv("APP_NAME", "not set")
    env = os.getenv("APP_ENV", "not set")
    return f"APP_NAME={name}\nAPP_ENV={env}\nLab 6 is running\n"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
