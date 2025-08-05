---
slug: "json-rails"
title: "ActiveRecord поиск по JSON полям"
description: "Небольшой гайд как в RubyOnRails при помощи ActiveRecord осуществлять поиск по JSON полям. Также будет приведен пример, как сделать поиск по вложенным JSON полям. Небольшая шпаргалка на все случаи жизни."
summary: "Небольшой гайд как в RubyOnRails при помощи ActiveRecord осуществлять поиск по JSON полям. Также будет приведен пример, как сделать поиск по вложенным JSON полям. Небольшая шпаргалка на все случаи жизни."
image: "/images/posts/json-rails.png"
date: 2021-09-27
tags: [json rails ruby]
---

![ActiveRecord поиск по JSON полям](/images/posts/json-rails.png "ActiveRecord поиск по JSON полям")

### Как искать по JSON полям
В нашем примере поле `data_json` будет иметь тип json, а `ModelName` - название модели.

Если нужно сделать поиск по верхнеуровневому ключу 'key', то запрос будет выглядеть следующим образом:

```ruby
# data_json = { "key": "value" }

ModelName.where("data_json->>'key' = ?", "value")
```

Для поиска по вложенным ключам можно использовать конструкции, представленные ниже (результат один и тот же, но во втором примере реализовано через цепочку операторов):
```ruby
# data_json = { "a": { "b": "value" }}

ModelName.where("data_json->>'{a,b}' = ?", "value")

ModelName.where("data_json->'a'->>'b' = ?", "value")
```