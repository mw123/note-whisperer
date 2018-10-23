FROM python:3

RUN apt-get update && apt-get install -y mysql-client && rm -rf /var/lib/apt

WORKDIR /usr/src/KGS

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
EXPOSE 5001

CMD [ "python", "./KGS.py" ]