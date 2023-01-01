from tkinter import *
from tkinter import ttk

class UI:

    def __init__(self, ui):
        ui.title("Bouncing Ball")

        mainframe = ttk.Frame(ui, padding="3 3 12 12")
        mainframe.grid(column=0, row=0, sticky=(N, W, E, S))
        ui.columnconfigure(0, weight=1)
        ui.rowconfigure(0, weight=1)

        self.wind_x = DoubleVar()
        self.wind_y = DoubleVar()
        self.wind_z = DoubleVar()
        self.x_label = StringVar()
        self.y_label = StringVar()
        self.z_label = StringVar()

        self.show_x_label()
        self.show_y_label()
        self.show_z_label()

        self.air_resist = DoubleVar(mainframe, 0.5)
        self.air_label = StringVar()

        self.show_air_label()

        self.grav = DoubleVar(mainframe, -10.0)
        self.grav_label = StringVar()

        self.show_grav_label()

        self.cr = DoubleVar(mainframe, 0.5)
        self.cf = DoubleVar(mainframe, 0.5)
        self.cr_label = StringVar()
        self.cf_label = StringVar()

        self.show_cr_label()
        self.show_cf_label()

        ttk.Label(mainframe, textvariable=self.x_label).grid(column=2, row=0, sticky=(W, E))
        slider_windx = ttk.Scale(
            mainframe, orient=HORIZONTAL, 
            length=200, from_=-100, to=100, 
            variable=self.wind_x, command=self.show_x_label
        ).grid(column=1, row=0, sticky=(W, E))

        ttk.Label(mainframe, textvariable=self.y_label).grid(column=2, row=1, sticky=(W, E))
        slider_windy = ttk.Scale(
            mainframe, orient=HORIZONTAL, 
            length=200, from_=-100, to=100, 
            variable=self.wind_y, command=self.show_y_label
        ).grid(column=1, row=1, sticky=(W, E))

        ttk.Label(mainframe, textvariable=self.z_label).grid(column=2, row=2, sticky=(W, E))
        slider_windz = ttk.Scale(
            mainframe, orient=HORIZONTAL, 
            length=200, from_=-100, to=100, 
            variable=self.wind_z, command=self.show_z_label
        ).grid(column=1, row=2, sticky=(W, E))

        ttk.Label(mainframe, textvariable=self.air_label).grid(column=2, row=3, sticky=(W, E))
        slider_air = ttk.Scale(
            mainframe, orient=HORIZONTAL, 
            length=200, from_=-100, to=100, 
            variable=self.air_resist, command=self.show_air_label
        ).grid(column=1, row=3, sticky=(W, E))

        ttk.Label(mainframe, textvariable=self.grav_label).grid(column=2, row=4, sticky=(W, E))
        slider_grav = ttk.Scale(
            mainframe, orient=HORIZONTAL, 
            length=200, from_=-100, to=100, 
            variable=self.grav, command=self.show_grav_label
        ).grid(column=1, row=4, sticky=(W, E))

        ttk.Label(mainframe, textvariable=self.cr_label).grid(column=2, row=5, sticky=(W, E))
        slider_cr = ttk.Scale(
            mainframe, orient=HORIZONTAL, 
            length=200, from_=0.0, to=1.0, 
            variable=self.cr, command=self.show_cr_label
        ).grid(column=1, row=5, sticky=(W, E))

        ttk.Label(mainframe, textvariable=self.cf_label).grid(column=2, row=6, sticky=(W, E))
        slider_cf = ttk.Scale(
            mainframe, orient=HORIZONTAL, 
            length=200, from_=0.0, to=1.0, 
            variable=self.cf, command=self.show_cf_label
        ).grid(column=1, row=6, sticky=(W, E))

    def show_x_label(self, *args):
        self.x_label.set("Wind X: " + str(int(self.wind_x.get())))
        return

    def show_y_label(self, *args):
        self.y_label.set("Wind Y: " + str(int(self.wind_y.get())))
        return

    def show_z_label(self, *args):
        self.z_label.set("Wind Z: " + str(int(self.wind_z.get())))
        return

    def show_air_label(self, *args):
        self.air_label.set("Air Resist: " + str("%.2f" % float(self.air_resist.get())))

    def show_grav_label(self, *args):
        self.grav_label.set("Gravity: " + str(int(self.grav.get())))
        return

    def show_cr_label(self, *args):
        self.cr_label.set("Bounce: " + str("%.2f" % float(self.cr.get())))
        return

    def show_cf_label(self, *args):
        self.cf_label.set("Friction: " + str("%.2f" % float(self.cf.get())))
        return
