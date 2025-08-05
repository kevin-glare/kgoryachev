---
slug: "facebook-auth"
title: "Авторизация через Facebook API"
description: "Если вам необходимо реализовать вход в веб-приложение или приложение для компьютера через браузер без использования наших SDK, можно создать для себя процесс входа с использованием перенаправлений в браузере."
summary: "Если вам необходимо реализовать вход в веб-приложение или приложение для компьютера через браузер без использования наших SDK, можно создать для себя процесс входа с использованием перенаправлений в браузере."
image: "/posts/fb.jpeg"
date: 2021-09-29
tags: [facebook meta]
---

![Авторизация через Facebook API](/posts/fb.jpeg "Авторизация через Facebook API")

### Сразу к сути
Перейдите в браузере на страницу _https://www.facebook.com/v12.0/dialog/oauth_ с необходимыми параметрами:

- _client_id_:  ID приложения, который можно найти в его панели.
- _redirect_uri_: URL, на который будет перенаправлен входящий пользователь.
- _state_: Строковое значение, создаваемое приложением для сохранения статуса между запросом и обратным вызовом. Этот параметр предназначен для защиты от [межсайтовой подделки запросов](https://en.wikipedia.org/wiki/Cross-site_request_forgery) и передается обратно без изменений в URI перенаправления.
- _response_type_: Указывает, куда будут добавлены данные ответа при перенаправлении обратно в приложение: в параметры или во фрагменты URL. Сведения о том, какой тип приложения выбрать, см. в [этом разделе](https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow/#confirm). 
- _scope_: Разделенный запятыми или пробелами список [разрешений](https://developers.facebook.com/docs/facebook-login/permissions/), которые нужно запросить у пользователя приложения.

Пример url:
```sh
https://www.facebook.com/v12.0/dialog/oauth?client_id=123456&redirect_uri=https://example.com/&scope=instagram_basic,instagram_content_publish,instagram_manage_insights,pages_show_list,pages_read_engagement&response_type=token&state=test_state
```

Ответ:

Произойдет редирект на указанный _redirect_uri_. Нам необходимо сверить _state_ и сохранить себе токены
```sh
https://example.com/?#access_token=EAAFdpebGQLAMABxSpKZC5xwH4d6pS7CdAZADASiW2ZBdbGYlsHAkTjh6mGpE66aEL6mZAPi6TaQcYcfu2lZBOyvDsy7WkcBM3U5J0uCuB7g0uG7ZBAd62rI4ZCZCuDct4CzVgcZA8tfrunm3pRXCbhHhlpf2Xa280umGw2UAwz3VZAAfpLOTC1u3UesRuuhLbQwdNvxO5Y8pvOBZCk0vIwPUnqg&data_access_expiration_time=1343274084&expires_in=7116&long_lived_token=EAAFcpebGQLABAGC0OdZBd28h6f4GDFXdsUGJsN3C7YdvfX2CmWXCGZAHQlZBAsSsZCcTURa8dSsg1LgtNHpwnSJMUHoZA3VV3DG5tj5ZBm2K8ZCSBNBJ2oK1M9QqJHxN08EGQ9WKPok4XjmJKxR7ZC3dnnCfsvkCcZC5WJXhJ3IoxjytWsoPw2iEO&state=test_state
```

### Полезные ссылки:
- [Get ccess token - Graph API OAuth 2.0](https://youtu.be/iN9Y7twSz7M)
- [Graph API User Accounts - Документация - Meta for Developers](https://developers.facebook.com/docs/graph-api/reference/user/accounts/)
- [Разработка процесса входа вручную](https://developers.facebook.com/docs/facebook-login/manually-build-a-login-flow/)