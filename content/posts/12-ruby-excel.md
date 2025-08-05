---
slug: "ruby-excel"
title: "Генерация больших excel файлов"
description: "Для генерации excel файлов мы чаще всего используем roo или axlsx/caxlsx. Они прекрасно работают, имеют огромный функционал и активное комьюнити. Но иногда для счастья этого оказывается мало."
summary: "Для генерации excel файлов мы чаще всего используем roo или axlsx/caxlsx. Они прекрасно работают, имеют огромный функционал и активное комьюнити. Но иногда для счастья этого оказывается мало."
image: "../posts/excel.png"
date: 2023-02-28
tags: [ruby excel]
---

![Генерация больших excel файлов](../../posts/excel.png "Генерация больших excel файлов")

### Приступим
Для генерации excel файлов мы чаще всего используем roo или _axlsx/caxlsx_. Они прекрасно работают, имеют огромный функционал и активное комьюнити. Но иногда для счастья этого оказывается мало.

В качестве источника данных возьмем готовые таблицы: 
```sh
1) users - 38832 записей
2) comments - 2728260 записей
```

Попробуем сгенерировать файл при помощи caxlsx:
```ruby
p = Axlsx::Package.new
wb = p.workbook
wb.add_worksheet do |sheet|
  User.dataset.paged_each do |row|
    sheet.add_row row.values.values
  end
end
stream = p.to_stream
File.open('users.xlsx', 'wb') { |f| f.write(stream.read) }
```
- Файл успешно сгенерировался, потребление оперативной памяти составило _~100 MB_. 
- Теперь попробуем прогнать большую таблицу comments. К сожалению, нам не хватило _ОЗУ_, и _OOM Killer_ прибил нас. 

Первое, что приходит на ум - решить проблему инкрементальной записью чанков в файл, как мы это сделали бы в случае с _csv_:
```ruby
file = File.open('users.csv', 'w')
User.dataset.paged_each do |row|
  file.write row.values.values.join(";")
end
file.close
```
Но после того, как я увидел структуру файла _.xlsx_, у меня появились сомнения.

![Генерация больших excel файлов](../../posts/excel-1.jpg "Генерация больших excel файлов")

### Эксперименты

Я изучил много инфы, stackoverflow утверждал, что нельзя построчно записывать в файл, но решил, что решение должно быть и я не один с этим столкнулся. 
Переключился на структуру файлов и поиск возможных решений на других языках. В итоге наткнулся на Libxlsxwriter на С, потом на статью и даже на гем.

Давайте посмотрим, что из этого вышло:

- _caxlsx_
```ruby
users - 91.05 MB
RAM USAGE (start): 446696 K
RAM USAGE (end): 539936 K

comments - ??? MB
RAM USAGE (start): 444460 K
RAM USAGE (end): Killed (кончилась память)
```

- _xlsxwriter_:
```
users - 38.42 MB
RAM USAGE (start): 444292 K
RAM USAGE (end): 483636 K

comments - 1597.96 MB
RAM USAGE (start): 443776 K
RAM USAGE (end): 2080096 K
```
Уже лучше, но 1.5GB тоже много. Решил посмотреть, что можно с этим сделать и нашел опцию - _constant_memory_.

- _xlsxwriter with constant_memory_:
```ruby
users - 8.26 MB
RAM USAGE (start): 445720 K
RAM USAGE (end): 454184 K

comments - 8.28 MB
RAM USAGE (start): 445780 K
RAM USAGE (end): 454260 K
```

Результат налицо: теперь генерация файла любого объема будет потреблять _~8 MB ОЗУ_. Если сравнивать функциональность этого гема с _axlsx_, то _xlsxwriter_ не имеет возможности считывать данные из текущего состояния и не имеет никакой интеграции с рельсами. Но я все равно считаю это отличным бустом производительности.

### Полезные ссылки
- [libxlsxwriter](https://github.com/jmcnamara/libxlsxwriter)
- [xlsxwriter-rb](https://github.com/gekola/xlsxwriter-rb)
- [Working with Memory and Performance](https://xlsxwriter.readthedocs.io/working_with_memory.html)
