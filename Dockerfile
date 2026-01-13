FROM python:3.11-slim

# Install keymap-drawer
RUN pip install --no-cache-dir keymap-drawer

WORKDIR /workdir
