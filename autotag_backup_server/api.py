
import os
import re
import logging

from typing_extensions import Annotated
from fastapi import FastAPI, Body, UploadFile, File

# from pydantic import BaseModel, Field

logger = logging.getLogger("uvicorn")
# logging.basicConfig(format='%(asctime)s %(levelname)s %(process)d %(filename)s:%(lineno)d %(message)s')
logger.setLevel("INFO")
logger.info("Testing LOGGGGGG")
logger.info("uvicorn has %d logger(s)" % len(logger.handlers))

if len(logger.handlers) > 0:
    logger.handlers[0].setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s %(process)d %(filename)s:%(lineno)d %(message)s'))
# logger.removeHandler()
else:
    ch = logging.StreamHandler()
    ch.setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s %(process)d %(filename)s:%(lineno)d %(message)s'))
    logger.addHandler(ch)
    logger.propagate = True


app = FastAPI()

root_folder = os.path.join(os.path.dirname(__file__), 'api_data')

# ts_format = "%d %B %Y %I:%M:%S %p"


@app.get("/up_test/")
def api_hello():
    return {'message': 'Yaay! FastAPI it is!!!'}


@app.post("/upload/")
def api_index(
        file_path: Annotated[str, Body(description='Path to file', embed=True)],
        file: Annotated[UploadFile, File(description='File to be indexed, an image')],
        db_name: Annotated[str, Body(description='db to use', embed=True)] = 'default'):

    logger.info(str(file.filename))
    logger.info('file mode - ' + str(file.file.mode))

    # TODO: validate this is actually an image file

    # TODO: file_path should not start with '/', neither db_name should have '/' - must be a valid folder name,
    # limit to simple chars
    save_path = os.path.join(root_folder, db_name, file_path)
    save_dir = os.path.dirname(save_path)
    os.makedirs(save_dir, exist_ok=True)

    with open(save_path, 'wb') as f:
        f.write(file.file.read())

    return {'message': 'success'}


# TODO:
# @app.post("/download/")
