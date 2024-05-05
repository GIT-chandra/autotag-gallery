
import os
from io import BytesIO
from PIL import Image
import logging

from typing_extensions import Annotated
from fastapi import FastAPI, Body, UploadFile, File, Response

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

# non-endpoint functions

# # targetting a ~3.2 MP image
# res_large = 2064.0
# res_small = 1552.0

# targetting 2 MP image
res_large = 1920
res_small = 1080


def get_1080p_res(og_width: int, og_height: int):
    if og_height > og_width:
        # portrait image
        tw, th = res_small, res_large
    elif og_width > og_height:
        # landscape
        tw, th = res_large, res_small
    logger.info("finding resolution to scale down to for input wxh: %d x %d" % (
        og_width, og_height))
    scale_x, scale_y = tw / og_width, th / og_height

    if scale_x >= 1 and scale_y >= 1:
        # image is already smaller in both dimensions
        logger.info("not scaling - image not larger enough")
        return og_width, og_height

    #  pick the smaller of the two, and scale both dimensions with that
    # so that no part of the image gets cropped, and aspect ratio is preserved
    scale = min(scale_x, scale_y)
    return int(scale * og_width), int(scale*og_height)


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

    if len(os.path.abspath(save_dir)) < len(os.path.abspath(root_folder)):
        # prevent abuse of file_path, to write outside of root_folder
        return Response(status_code=403)
    os.makedirs(save_dir, exist_ok=True)

    with open(save_path, 'wb') as f:
        og_size_bytes = f.write(file.file.read())

    #  generate smaller image, send that back
    pil_img = Image.open(file.file)
    img_w, img_h = pil_img.size[:2]

    # find aspect ratio retained image resolution
    target_w, target_h = get_1080p_res(img_w, img_h)
    logger.info("target resolution - %d x %d" % (target_w, target_h))

    if target_w != img_w or target_h != img_h:
        pil_resized = pil_img.resize((target_w, target_h), Image.LANCZOS)

        temp = BytesIO()

        img_format = pil_img.format
        logger.info("format - %s" % img_format)

        pil_resized.save(temp, format=img_format, optimize=True, quality=75)
        resized_size_bytes = temp.getbuffer().nbytes

        logger.info("file size shaved - {0:.2f} %".format(
            float(og_size_bytes - resized_size_bytes) * 100.0 / og_size_bytes))

        return Response(content=temp.getvalue(), media_type="image/%s" % img_format.lower(), status_code=200)

    return Response(status_code=204)


@app.get("/list_dbs/")
def api_list_dbs():
    dbs = []
    for ff in os.listdir(root_folder):
        if os.path.isdir(os.path.join(root_folder, ff)):
            dbs.append(ff)
    return {'message': 'success', 'dbs': dbs}


# TODO:
# @app.post("/download/")
