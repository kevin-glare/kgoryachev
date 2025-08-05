---
slug: "firebase-push"
title: "Отправка push уведомлений через Firebase Cloud Messaging"
description: "Firebase Cloud Messaging, ранее известная как Google Cloud Messaging, является кроссплатформенным облачным решением для отправки сообщений и уведомлений."
summary: "Firebase Cloud Messaging, ранее известная как Google Cloud Messaging, является кроссплатформенным облачным решением для отправки сообщений и уведомлений."
image: "/images/posts/firebase.png"
date: 2021-09-28
tags: [firebase google ruby]
---

![Отправка push уведомлений через Firebase Cloud Messaging](/images/posts/firebase.png "Отправка push уведомлений через Firebase Cloud Messaging")

### Что такое Firebase Cloud Messaging?
Firebase Cloud Messaging, ранее известная как Google Cloud Messaging, является кроссплатформенным облачным решением для сообщений и уведомлений для Android, iOS и веб-приложений, которое с 2021 года можно будет использовать бесплатно. 

### Отправка ивента
Первым делом необходимо сгенерировать JSON файл c ключами. Для этого перейдите в консоль Firebase и в разделе _Project Settings_ -> _Service Accounts_ -> _Firebase Admin SDK_ нажмите _GENERATE NEW PRIVATE KEY_.

Для отправки сообщения нам понадобится:
1. URL для отправки сообщения
2. Body параметры сообщения
3. Header с токеном

URL для отправки сообщения:
```ruby
# FCM_PROJECT_ID - project_id из JSON файла

BASE_URL = "https://fcm.googleapis.com/v1/projects/#{FCM_PROJECT_ID}/messages:send".freeze
```

Параметры сообщения:
```ruby
# 1. PUSH_TOKEN_CLIENT - пуш токен с мобильного устройства
# 2. если нужно добавить кастомные параметры для iOS, то добавьте их 
#    внутрь payload
# 3. В message можно положить структуру notification c ключами title и 
#    body

def message
  {
    message: {
      token: PUSH_TOKEN_CLIENT,
      apns: {
        payload: {
          aps: {
            category: "PUBLISHED",
            'mutable-content': 1,
            alert: {
              'title-loc-key': "TITLE",
              'loc-key': "BODY"
            }
          },
          'custom-key-1': 1
        }
      }
    }
  }
end
```

Для генерации токена, я использую гем _googleauth_:
```ruby
FCM_FILENAME = ENV['FCM_FILENAME'].freeze # имя json файла
FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging'.freeze

authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
  json_key_io: File.open(File.join(Rails.root, FCM_FILENAME)),
  scope: FCM_SCOPE
)

token = authorizer.fetch_access_token!
token['access_token']
# p.s. access_token имеет очень много точек в конце (758 шт), их можно # не обрезать.
```

В итоге у нас получается такой cURL:
```sh
curl --location --request POST 'https://fcm.googleapis.com/v1/projects/ingrid-ios/messages:send' \
--header 'Authorization: Bearer ya29.c.b0AXv0zTNWOmw56js-3ohmLBZU018M11vitwg6-Vj_nQB_zudD3OemCk5wpVtiOY5m6Ahv45ufliMNUsOYwoYE4X0sM8JDULL1ZdfWUmm_yFD2R-J0sQ15flcJK-X0IDaUQOqXe_BhWmaTDFtbU1yJHHhaYhZ9l1gvVhPWf6ZqyJlopvbwe2k8TBIN--FKqq7eQt0hc5uNqAfRmeYRyetvPs0eDXn_gs4' \
--header 'Content-Type: application/json' \
--data-raw '{
    "message": {
        "token": "dyScobpul03ygFTr-K9gJk:ATA91bHQMIcL97SOSRiCiqEw6s-laT16VtkRJmC5gWcyVdCbycwio0v_DqnS68rX7Ndvfwoc2wqdIeI7XGnNpKy3eraJpZbqtVcNmdZ-sVPEWnoT2g5RZwVo1eRRoV_ipX056qW-wxht",
        "apns": {
            "payload": {
                "aps": {
                    "category": "PUBLISHED",
                    "mutable-content": 1,
                    "alert": {
                        "title-loc-key": "TITLE",
                        "loc-key": "BODY"
                    }
                },
                "custom-key-1": 1
            }
        }
    }
}'
```

В ответ получим:
```json
{
  "name": "projects/FCM_PROJECT_ID/messages/1636421835494776"
}
```

##### Личные наблюдения:
- Для отправки пушицы уведомления на андроид - можно все обернуть в ключ _"data"_ внутри объекта _"message"_;
- Eсли добавить объект _"notification"_, то андроид автоматически покажет нотификацию пользователю (приложение не успеет распарсить объект уведомления и переделать пуш).

### Полезные ссылки:
- [google-auth-library-ruby
](https://github.com/googleapis/google-auth-library-ruby)
- [Push уведомления в Android с помощью Firebase Cloud Messaging для начинающих](https://habr.com/ru/post/302002/)
- [Создание запросов на отправку сервера приложений](https://firebase.google.com/docs/cloud-messaging/send-message?hl=ru)