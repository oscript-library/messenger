﻿
///////////////////////////////////////////////////////////////////////////////////////////////
//
// Модуль транспорта отправки сообщений telegram
//
///////////////////////////////////////////////////////////////////////////////////////////////

Перем ПараметрыАвторизации;	// хранит структуру авторизации
Перем ОписаниеПротокола;	// хранит структуру описания протокола

///////////////////////////////////////////////////////////////////////////////////////////////
// Стандартный интерфейс
///////////////////////////////////////////////////////////////////////////////////////////////

// Протокол
//	Метод возвращает описание используемого протокола
//
// Возвращаемое значение:
//	Структура - Описание протокола
//		{
//			Имя 			- Строка - Системное имя транспорта
//			Представление 	- Строка - пользовательское представление транспорта
//			Описание		- Строка - Строковое описание транспорта
//			Операторы		- Структура - Возможные операторы транспорта
//		}
//
Функция Протокол() Экспорт
	
	Если ОписаниеПротокола = Неопределено Тогда
		
		ОписаниеПротокола = Новый Структура("Имя, Представление, Описание, Операторы", "telegram", "telegram", "Отправка сообщений в каналы telegram", Неопределено);
		
	КонецЕсли;
	
	Возврат ОписаниеПротокола;
	
КонецФункции // Протокол()

// Инициализация
//	Инициализация параметров транспорта
//
// Параметры:
//  ПараметрыИнициализации - Структура - набор параметров инициализации
//
Процедура Инициализация(ПараметрыИнициализации) Экспорт
	
	Если ПараметрыИнициализации = Неопределено Тогда
		
		Сообщить(СтрШаблон("Для инициализации транспорта %1 необходимо передавать в параметрах: ", Протокол().Представление));
		Сообщить(" - Логин");
		
		ВызватьИсключение СтрШаблон("Инициализация транспорта %1 невыполнена", Протокол().Представление);
		
	КонецЕсли;
	
	ПараметрыАвторизации = Новый Структура("Токен", ПараметрыИнициализации.Логин);
	
КонецПроцедуры // Инициализация()

// ОтправитьСообщение
//	Метод отправки сообщения
//
// Параметры:
//	Адресат					- Строка	- Адресат сообщения
//	Сообщение				- Строка	- Текст отправляемого сообщения
//	ДополнительныеПараметры	- Структура	- Набор дополнительных параметров
//
Процедура ОтправитьСообщение(Адресат, Сообщение, ДополнительныеПараметры = Неопределено) Экспорт
	
	Если ПараметрыАвторизации = Неопределено Тогда
		
		ВызватьИсключение СтрШаблон("Для отправки сообщения необходимо выполнить инициализацию транспорта %1", Протокол().Представление);
		
	КонецЕсли;
	
	УстановитьЭмоджи(Сообщение);

	ПараметрыСообщения = Новый Структура("chat_id, text", Адресат, Сообщение);

	ОпределитьТипСообщения(ДополнительныеПараметры, ПараметрыСообщения);

	Попытка
		ОтветHTTP = ВызватьМетодTelegramAPI("sendMessage", ПараметрыСообщения);
		Если ОтветHTTP.КодСостояния <> 200 Тогда
			ОтправкаВСлучаеОшибок(ПараметрыСообщения);
		КонецЕсли;
	Исключение  
		ОтправкаВСлучаеОшибок(ПараметрыСообщения);
	КонецПопытки;

КонецПроцедуры // ОтправитьСообщение()

Процедура ОтправкаВСлучаеОшибок(ПараметрыСообщения)

	КодСостоянияСоединения = 301;
	КоличествоПопытокПодключения = 0;

	Пока ((КодСостоянияСоединения > 300) И (КоличествоПопытокПодключения < 25)) Цикл	
		Попытка
			Прокси                       = СоздатьДинамическийПрокси(КоличествоПопытокПодключения);	
			ОтветHTTP                    = ВызватьМетодTelegramAPI("sendMessage", ПараметрыСообщения, Прокси);
			КодСостоянияСоединения       = ОтветHTTP.КодСостояния;
			КоличествоПопытокПодключения = КоличествоПопытокПодключения + 1;
		Исключение
			Приостановить(2);
			КоличествоПопытокПодключения = КоличествоПопытокПодключения + 1;
		КонецПопытки;
	КонецЦикла;
	
КонецПроцедуры

///////////////////////////////////////////////////////////////////////////////////////////////
// Методы реализации
///////////////////////////////////////////////////////////////////////////////////////////////
Функция ВызватьМетодTelegramAPI(ИмяМетода, Параметры, Прокси = Неопределено)
	
	ИмяСервера = "https://api.telegram.org";
	
	URL = "/bot" + ПараметрыАвторизации.Токен
		+ "/" + ИмяМетода + "?";
	
	HTTPЗапрос = Новый HTTPЗапрос(URL);

	Заголовки = Новый Соответствие;
	Заголовки.Вставить("Content-Type","application/json");
 	HTTPЗапрос.Заголовки = Заголовки;

	HTTPЗапрос.УстановитьТелоИзСтроки(ДанныеВJSON(Параметры));

	HTTP = Новый HTTPСоединение(ИмяСервера, 443, , , Прокси, 3);
	ОтветHTTP = HTTP.ОтправитьДляОбработки(HTTPЗапрос);
	
	Возврат ОтветHTTP;
	
КонецФункции

Функция СоздатьДинамическийПрокси(НомерПопытки)
	ИмяСервера = "https://www.proxy-list.download";
	URL = "api/v1/get?type=https&anon=transparent&country=NL";

	HTTPЗапрос = Новый HTTPЗапрос(URL);
	HTTP = Новый HTTPСоединение(ИмяСервера);
	ОтветHTTP = HTTP.Получить(HTTPЗапрос);
	Ответ = ОтветHTTP.ПолучитьТелоКакСтроку();

	МассивСтрок = Новый Массив();
	Для Н = 1 По СтрЧислоСтрок(Ответ) Цикл
		Строка = СтрЗаменить(СтрПолучитьСтроку(Ответ, Н), Символы.ВК, "");
		МассивСтрок.Добавить(СтрРазделить(Строка, ":"));
	КонецЦикла;

	ProxyIP = МассивСтрок[НомерПопытки][0];
	ProxyPort = Число(МассивСтрок[НомерПопытки][1]);
	Прокси = Новый ИнтернетПрокси(Ложь);
	Прокси.Установить("https", ProxyIP, ProxyPort, "", "", Ложь);
	Возврат Прокси;

КонецФункции

Процедура ОпределитьТипСообщения(ДополнительныеПараметры, ПараметрыСообщения)
	Если ДополнительныеПараметры <> Неопределено 
		И
		ДополнительныеПараметры.Свойство("ТипСообщения") Тогда
		ТипСообщения = НРег(ДополнительныеПараметры.ТипСообщения);
		Если ТипСообщения = "html" Тогда
			ПараметрыСообщения.Вставить("parse_mode", "html");
		ИначеЕсли ТипСообщения = "markdown" или ТипСообщения = "md" Тогда
			ПараметрыСообщения.Вставить("parse_mode", "Markdown");
		КонецЕсли;
	КонецЕсли;
КонецПроцедуры

Функция ДанныеВJSON(Данные)
	ЗаписьJSON = Новый ЗаписьJSON;
	ЗаписьJSON.УстановитьСтроку();
	ЗаписатьJSON(ЗаписьJSON, Данные);
	Возврат ЗаписьJSON.Закрыть();
КонецФункции

Процедура УстановитьЭмоджи(Текст)
	мШаблоны = СтрРазделить("\U;\u;U+", ";", Ложь);
	СоответствиеHEXtoDEC = СоответствиеHEXtoDEC();
	Длина = СтрДлина(Текст);
	Для каждого Шаблон Из мШаблоны Цикл
		Поз = СтрНайти(Текст, Шаблон);
		Пока Поз > 0 Цикл
			ЗначениеHEX = "";
			сч = Поз + 2;
			Пока сч <= Длина И СоответствиеHEXtoDEC[Врег(Сред(Текст, сч, 1))] <> Неопределено Цикл
				ЗначениеHEX = ЗначениеHEX + Сред(Текст, сч, 1);
				сч = сч + 1;
			КонецЦикла;
			КодСимвола = ЧислоИзШестнадцатеричнойСтроки(ЗначениеHEX);
			Текст = СтрЗаменить(Текст, Шаблон + ЗначениеHEX, Символ(КодСимвола));
			Поз = СтрНайти(Текст, Шаблон);
		КонецЦикла;
	КонецЦикла;
КонецПроцедуры

Функция ЧислоИзШестнадцатеричнойСтроки(Знач ЗначениеHEX)

	СоответствиеHEXtoDEC = СоответствиеHEXtoDEC();

	Результат = 0;
	Степень = СтрДлина(ЗначениеHEX) - 1;

	Для Поз = 1 По СтрДлина(ЗначениеHEX) Цикл
		СимволHEX = Сред(ЗначениеHEX, Поз, 1);
		ЗначениеDec = СоответствиеHEXtoDEC[СимволHEX];
		Если ЗначениеDec = Неопределено Тогда
			ВызватьИсключение СтрШаблон("Конвертация HEX to DEC невозможна:
			|%1 - недопустимый символ %2 в позиции %3",
			ЗначениеHEX, СимволHEX, Поз);
		КонецЕсли;
		Результат = Результат + ЗначениеDec * Pow(16, Степень);
		Степень = Степень - 1;
	КонецЦикла;
	
	Возврат Результат;
	
КонецФункции

Функция СоответствиеHEXtoDEC()
	СтрокаСоотвествий = "0:0,1:1,2:2,3:3,4:4,5:5,6:6,7:7,8:8,9:9,"
					  + "A:10,B:11,C:12,D:13,E:14,F:15";
	СоответствиеHEXtoDEC = Новый Соответствие();
	Для каждого ПараЗначений Из СтрРазделить(СтрокаСоотвествий, ",") Цикл
		КЗ = СтрРазделить(ПараЗначений, ":");
		СоответствиеHEXtoDEC.Вставить(КЗ[0], Число(КЗ[1]));
	КонецЦикла;
	Возврат СоответствиеHEXtoDEC;
КонецФункции

///////////////////////////////////////////////////////////////////////////////////////////////

ПараметрыАвторизации = Неопределено;
