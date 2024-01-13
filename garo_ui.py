from tkinter import ttk
import tkinter as tk
import os
from PIL import ImageTk, Image

from garo_core import GaroCoreBase
from garo_config import GaroConfig

# Thanks to https://stackoverflow.com/a/68701602/7450160


class ScrollableFrame:
    """
    # How to use class
    from tkinter import *
    obj = ScrollableFrame(master,height=300 # Total required height of canvas,width=400 # Total width of master)
    objframe = obj.frame
    # use objframe as the main window to make widget
    """

    def __init__(self, master, width, height, mousescroll=0):
        self.mousescroll = mousescroll
        self.master = master
        self.height = height
        self.width = width
        self.main_frame = ttk.Frame(self.master)
        self.main_frame.pack(fill=tk.BOTH, expand=1)

        self.scrollbar = ttk.Scrollbar(self.main_frame, orient='vertical')
        self.scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        self.canvas = tk.Canvas(
            self.main_frame, yscrollcommand=self.scrollbar.set)
        self.canvas.pack(expand=True, fill=tk.BOTH)

        self.scrollbar.config(command=self.canvas.yview)

        self.canvas.bind('<Configure>', lambda e: self.canvas.configure(
            scrollregion=self.canvas.bbox("all")))

        self.frame = ttk.Frame(
            self.canvas, width=self.width, height=self.height)
        self.frame.pack(expand=True, fill=tk.BOTH)
        self.canvas.create_window((0, 0), window=self.frame, anchor="nw")

        self.frame.bind("<Enter>", self.entered)
        self.frame.bind("<Leave>", self.left)

    def _on_mouse_wheel(self, event):
        self.canvas.yview_scroll(-1 * int((event.delta / 120)), "units")

    def entered(self, event):
        if self.mousescroll:
            self.canvas.bind_all("<MouseWheel>", self._on_mouse_wheel)

    def left(self, event):
        if self.mousescroll:
            self.canvas.unbind_all("<MouseWheel>")


class GaroApp(object):
    def __init__(self, core: GaroCoreBase, cfg: GaroConfig) -> None:
        self.core = core
        self.cfg = cfg
        self.ui_root = tk.Tk(className=self.cfg.app_name)
        self.ui_root.title(self.cfg.app_name)
        self.scroll = ScrollableFrame(
            self.ui_root, width=400, height=300, mousescroll=1)
        # self.button = ttk.Button(self.scroll.frame, text="Hello")
        # self.button.grid(row=0, column=0)
        # ttk.Button(self.scroll.frame, text="World").grid(row=1, column=0)

        # for i in range(10):
        #     ttk.Button(self.scroll.frame, text="Button %d" % i).grid(row=i+2, column=0)

        self.item_images = []
        self.folder_image = ImageTk.PhotoImage(
            Image.open(self.cfg.image_paths['folder']).resize((200, 200), Image.LANCZOS))
        for i, item in enumerate(self.core.get_contents()):
            print(item)
            if os.path.isdir(item):
                ttk.Label(self.scroll.frame, image=self.folder_image).grid(
                    row=i, column=0)
            elif item.endswith('.jpg'):
                self.item_images.append(ImageTk.PhotoImage(
                    Image.open(item).resize((200, 200), Image.LANCZOS)))
                ttk.Label(self.scroll.frame, image=self.item_images[-1]).grid(
                    row=i, column=0)

    def run(self):
        self.ui_root.mainloop()
