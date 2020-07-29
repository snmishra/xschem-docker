#!/bin/bash
vncserver :1 &
DISPLAY=:1 xschem
