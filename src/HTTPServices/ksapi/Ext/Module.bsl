﻿Функция ПодписатьФайл(Тело)
	
	Стк = XMLЗначение(Тип("ХранилищеЗначения"),тело).Получить();
	возврат Справочники.СертификатыКлючейЭлектроннойПодписиИШифрования.ПодписатьЭЦП(Стк.фио,Стк.таб);
	
КонецФункции


Функция GETGET(Запрос)
	Ответ = Новый HTTPСервисОтвет(200);
	
	Метод = ВРЕГ(Запрос.ПараметрыURL["ИмяМетода"]);
	
	СткПар = Новый Структура;
	
	Для каждого Эл из Запрос.ПараметрыЗапроса Цикл
		СткПар.Вставить(Эл.Ключ,Эл.Значение);	
	КонецЦикла;
	
	
	Если Метод = "TEST" Тогда
		Результат = "Test complete";
	ИначеЕсли Метод = "SINGFILE" Тогда
		Результат = ПодписатьФайл(Запрос.получитьТелокакСтроку());
	ИНаче
		Ответ.КодСостояния = 404;
		Результат = "Метод "+Метод+" не обнаружен";
	КонецеСли;
	
	Ответ.УстановитьТелоИзСтроки(Результат);
	Возврат Ответ;
	
КонецФункции

