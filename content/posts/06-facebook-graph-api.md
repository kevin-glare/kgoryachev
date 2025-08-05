---
slug: "facebook-grap-api"
title: "Facebook Graph Api"
description: "API Graph — это основной инструмент для загрузки данных на платформу Facebook и их получения оттуда. Он представляет собой API на базе HTTP, с помощью которого приложения могут обмениваться данными с fb."
summary: "API Graph — это основной инструмент для загрузки данных на платформу Facebook и их получения оттуда. Он представляет собой API на базе HTTP, с помощью которого приложения могут обмениваться данными с fb."
image: "/images/posts/fb-containers.jpg"
date: 2021-09-30
tags: [facebook ruby]
---

![Facebook Graph Api](/images/posts/fb-containers.jpg "Facebook Graph Api")

### Что такое Facebook Graph Api?
API Graph — это основной инструмент для загрузки данных на платформу Facebook и их получения оттуда. Он представляет собой API на базе HTTP, с помощью которого приложения могут программным путем запрашивать данные, публиковать новые истории, управлять рекламой, загружать фото и выполнять множество других задач.

### Создание контейнера
Для создания контейнера понадобится файл (фидео или фото) и описание (необязательно). 

**ВАЖНО** - срок жизни контейнера - 24 часа!
Для того чтобы создать контейнер необходимо выполнить запрос:

- URL для отправки сообщения
```ruby
# GRAPH_API_VERSION - на текущий момент v12.0
# CLIENT_ID - ид клиента для которого создаем контейнер

url = "https://graph.facebook.com/#{GRAPH_API_VERSION}/#{CLIENT_ID}/media
```

- Параметры
```ruby
# ACCESS_TOKEN - авторизационный токен клиента fb
# CAPTION - подпись к посту
# MEDIA_URL

params = {
  access_token: ACCESS_TOKEN,
  caption: CAPTION
}

# для фотографии
params[:image_url] = MEDIA_URL

# для видео
params[:video_url] = MEDIA_URL
params[:media_type] = 'VIDEO'
```

- cURL
```sh
curl --location --request POST 'https://graph.facebook.com/v12.0/123456/media?access_token=access_token&caption=test&image_url=https://site.ru/image.jpg'
```

- Ответ
```json
{ "id": "19162258963110160" } # id контейнера
```

### Статус контейнера
URL для отправки сообщения:
```ruby
# CONTAINER_ID - id контейнера который получили в предыдущем шаге

url = "https://graph.facebook.com/#{GRAPH_API_VERSION}/#{CONTAINER_ID}"
```

Параметры:
```ruby
{
  access_token: ACCESS_TOKEN,
  fields: 'status_code'
}
```
cURL:
```sh
curl --location --request GET 'https://graph.facebook.com/v12.0/19162258963110160?access_token=access_token&fields=status_code'
```

Ответ:
```json
{ "status_code": "FINISHED", "id": "19162258963110160" }
```

##### Возможные статусы:
- _EXPIRED_ - Контейнер не был опубликован в течение 24 часов, и срок его действия истек.
- _ERROR_ - Контейнеру не удалось завершить процесс публикации.
- _FINISHED_ - Контейнер и его медиа-объект готовы к публикации.
- _IN_PROGRESS_ - Контейнер все еще находится в процессе публикации.
- _PUBLISHED_ - Медиа-объект контейнера опубликован.

### Публикация контейнера
URL для отправки сообщения:
```ruby
# CONTAINER_ID - id контейнера который получили в предыдущем шаге

url = "https://graph.facebook.com/#{GRAPH_API_VERSION}/#{CLIENT_ID}/media_publish"
```

Параметры:
```ruby
{
  access_token: ACCESS_TOKEN,
  creation_id: CONTAINER_ID
}
```

cURL:
```sh
curl --location --request POST 'https://graph.facebook.com/v12.0/123456/media_publish?access_token=access_token&creation_id=19162258963110160'
```

Ответ:
```json
# id опубликованного поста
{ 
  "id": "19162258963110160" 
} 
```