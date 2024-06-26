FROM python:3.9 as compile-image

RUN groupadd --gid 2000 python
RUN useradd --uid 2000 --gid python --shell /usr/sbin/nologin --create-home python

RUN apt-get update
RUN apt-get install -y ffmpeg libsm6 libxext6

COPY pyproject* ./
# Uncomment before review
# COPY poetry.lock ./

RUN pip install poetry
RUN poetry config virtualenvs.create false
RUN poetry install --only main --no-interaction --no-ansi

RUN apt-get remove -y gcc cmake make
RUN rm -rf /var/lib/apt/lists/* && apt-get autoremove -y && apt-get clean
RUN pip uninstall pipenv poetry -y

FROM scratch AS runtime-image

ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    LANG="C.UTF-8" \
    PYTHON_VERSION=3.9.16 \
    PYTHONUNBUFFERED=1 \
    WORKDIR=/srv/www/ \
    PYTHONPATH=/srv/www
WORKDIR $WORKDIR

COPY --from=compile-image / /

COPY . .

RUN chown python:python /srv -R
EXPOSE 8000
USER python:python
# команда запуска приложения
CMD ["python", "wolf_assistant/app.py"]
