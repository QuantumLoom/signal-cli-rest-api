#!/bin/sh
uvicorn signal_cli_rest_api.app.main:app --host 0.0.0.0
