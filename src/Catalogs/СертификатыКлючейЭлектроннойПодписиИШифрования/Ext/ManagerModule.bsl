﻿Функция ФорматиндексФИО(ФИО) Экспорт
	
	Возврат НРЕГ(СтрЗаменить(ФИО," ",""));
	
КонецФункции

Функция НайтиПоФИО(ФИО) Экспорт
	
	Запрос = Новый Запрос;
	Запрос.Текст = "ВЫБРАТЬ
	               |	СертификатыКлючейЭлектроннойПодписиИШифрования.Ссылка КАК Ссылка,
	               |	СертификатыКлючейЭлектроннойПодписиИШифрования.ДатаНачала КАК ДатаНачала,
	               |	СертификатыКлючейЭлектроннойПодписиИШифрования.ДатаОкончания КАК ДатаОкончания
	               |ИЗ
	               |	Справочник.СертификатыКлючейЭлектроннойПодписиИШифрования КАК СертификатыКлючейЭлектроннойПодписиИШифрования
	               |ГДЕ
	               |	СертификатыКлючейЭлектроннойПодписиИШифрования.индексФИО = &индексФИО
	               |
	               |УПОРЯДОЧИТЬ ПО
	               |	ДатаОкончания УБЫВ";
	
	Запрос.УстановитьПараметр("индексФИО",ФорматиндексФИО(ФИО));
	
	текДт = текущаяДата();
	Выб = Запрос.Выполнить().Выбрать();
	Пока Выб.Следующий() Цикл
		Если  Выб.ДатаНачала <= текДт 
			и выб.ДатаОкончания > текДт Тогда
			Возврат Выб.ссылка;
		КонецЕСЛИ;
	КонецЦикла;
	
	Выб.Сбросить();
	Если Выб.Следующий() Тогда
		Возврат "Сертификат "+СокрлП(Выб.ссылка)+" истек.";
	Конецесли;
	
	Возврат "Не найден сертификат для "+ФИО;
	
КонецФункции

Функция ПодписатьЭЦП(ФИО,ТабДок) Экспорт
	
	Сертификат = НайтиПоФИО(ФИО);
	Если ТИПЗНЧ(Сертификат)<>Тип("СправочникСсылка.СертификатыКлючейЭлектроннойПодписиИШифрования")  Тогда
		Возврат Сертификат;
	КонецеСЛИ;
	
	имяФайлаПДФ = ПолучитьИмяВременногоФайла(".pdf");
	имяФайлаCИГ = стрЗаменить(имяФайлаПДФ,".pdf",".sig");
	имяФайлаЗИП = стрЗаменить(имяФайлаПДФ,".pdf",".zip");
	темпИмя     = Формат(ТекущаяДата(),"ДФ=yyyyMMdd")+"_"+СокрЛП(Новый УникальныйИдентификатор)+".zip";
	строкаQRКода=  "https://azureuttdiag.blob.core.windows.net/dsdocs/zip/"+темпИмя;
	
	
	ПолучитьФайл(ТабДок,Сертификат,имяФайлаПДФ,строкаQRКода);
	дд = Новый ДвоичныеДанные(имяФайлаПДФ);
	                                      
	Менеджер = Новый МенеджерКриптографии(Сертификат.ИмяМодуляКриптографии,"",Сертификат.ТипМодуляКриптографии,ИспользованиеИнтерактивногоРежимаКриптографии.НеИспользовать);
	Менеджер.ПарольДоступаКЗакрытомуКлючу = Сертификат.ПарольДоступаКЗакрытомуКлючу;
	
	ддсерт = Сертификат.ДанныеСертификата.Получить();
	серт = Новый СертификатКриптографии(ддсерт);
	
	ПотокФайла = Новый ПотокВПамяти();
	Менеджер.Подписать(дд,ПотокФайла,серт);

	
	резДД = ПотокФайла.ЗакрытьИПолучитьДвоичныеДанные();
	резДД.Записать(имяФайлаCИГ);//"C:\TEMP\7.sig");
	//резДД.Записать(стрЗаменить(имяФайлаПДФ,".pdf",".p7s");//"C:\TEMP\7.p7s");
	//ддсерт.Записать(стрЗаменить(имяФайлаПДФ,".pdf",".cer");//"C:\TEMP\7.cer");
	
	зип = новый ЗаписьZipФайла(имяФайлаЗип);
	Зип.Добавить(имяФайлаПДФ);
	Зип.Добавить(имяФайлаCИГ);
	зип.Записать();
	
	Бин = Новый ДвоичныеДанные(имяФайлаЗип);
	
	Адрес = ОтправитьФайлВАзур(Бин,темпИмя);
	
	УдалитьФайлы(имяФайлаПДФ);
	УдалитьФайлы(имяФайлаCИГ);
	УдалитьФайлы(имяФайлаЗип);
	
	Возврат Адрес;
	
КонецФункции

Функция СткПолучитьСоединениеАЗУР() 
	
	Стк = Новый Структура();
	
	Стк.Вставить("Сервер","azure1c.westeurope.cloudapp.azure.com");
	Стк.Вставить("Порт",80);
	Стк.Вставить("Логин","Serv");
	Стк.Вставить("Пароль","SERVgfhjkm");
	
	Возврат Стк;
	
КонецФункции

Функция ОтправитьФайлВАзур(Бин,имяФайла) 
	
	
	Стк = Новый Структура();
	Стк.Вставить("дд",Бин);
	Стк.Вставить("имя",имяФайла);
	Стк.Вставить("рсш",".jpeg");
	Стк.Вставить("контейнер","dsdocs");
	Стк.Вставить("каталог","zip");
	
	 СткСоединение = СткПолучитьСоединениеАЗУР();
	 
	Соединение = Новый HTTPСоединение(
	СткСоединение.Сервер, // сервер (хост)
	СткСоединение.Порт, // порт, по умолчанию для http используется 80, для https 443
	, // пользователь для доступа к серверу (если он есть)
	, // пароль для доступа к серверу (если он есть)
	, // здесь указывается прокси, если он есть
	, // таймаут в секундах, 0 или пусто - не устанавливать
	// защищенное соединение, если используется https
	);
	
	Запрос = Новый HTTPЗапрос("/ServiceMP/hs/ksAPI/PUTFILETOAZURE");
	
	Хранилище = Новый ХранилищеЗначения(Стк, Новый СжатиеДанных(5));
	Запрос.УстановитьТелоИзСтроки(XMLСтрока(Хранилище));
	
	
	Результат = Соединение.POST(Запрос);
	Если Результат.КодСостояния <> 200 Тогда 
		Возврат результат.ПолучитьТелоКакСтроку();
	КонецЕСЛИ;
	
	адрес =  результат.ПолучитьТелоКакСтроку();
	Сообщить(адрес);
	
	Возврат Адрес;
	
	
КонецФункции

#Область ФормированиеQRКода

Функция КомпонентаФормированияQRКода(Отказ)
	
	СистемнаяИнформация = Новый СистемнаяИнформация;
	Платформа = СистемнаяИнформация.ТипПлатформы;
	
	ТекстОшибки = НСтр("ru = 'Не удалось подключить внешнюю компоненту для генерации QR-кода'");
	
	Попытка
		Если ПодключитьВнешнююКомпоненту("ОбщийМакет.КомпонентаПечатиQRКода", "QR") Тогда
			QRCodeGenerator = Новый("AddIn.QR.QRCodeExtension");
		Иначе
			Сообщить(ТекстОшибки);
		КонецЕсли
	Исключение
		Сообщить(ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
	КонецПопытки;
	
	Возврат QRCodeGenerator;
	
КонецФункции
//=======================================================
// Возвращает двоичные данные для формирования QR кода.
//
// Параметры:
//  QRСтрока         - Строка - данные, которые необходимо разместить в QR-коде.
//
//  УровеньКоррекции - Число - уровень погрешности изображения при котором данный QR-код все еще возможно 100%
//                             распознать.
//                     Параметр должен иметь тип целого и принимать одно из 4 допустимых значений:
//                     0(7% погрешности), 1(15% погрешности), 2(25% погрешности), 3(35% погрешности).
//
//  Размер           - Число - определяет длину стороны выходного изображения в пикселях.
//                     Если минимально возможный размер изображения больше этого параметра - код сформирован не будет.
//
//  ТекстОшибки      - Строка - в этот параметр помещается описание возникшей ошибки (если возникла).
//
// Возвращаемое значение:
//  ДвоичныеДанные  - буфер, содержащий байты PNG-изображения QR-кода.
// 
// Пример:
//  
//  // Выводим на печать QR-код, содержащий в себе информацию зашифрованную по УФЭБС.
//
//  QRСтрока = УправлениеПечатью.ФорматнаяСтрокаУФЭБС(РеквизитыПлатежа);
//  ТекстОшибки = "";
//  ДанныеQRКода = УправлениеПечатью.ДанныеQRКода(QRСтрока, 0, 190, ТекстОшибки);
//  Если Не ПустаяСтрока(ТекстОшибки)
//      ОбщегоНазначенияКлиентСервер.СообщитьПользователю(ТекстОшибки);
//  КонецЕсли;
//
//  КартинкаQRКода = Новый Картинка(ДанныеQRКода);
//  ОбластьМакета.Рисунки.QRКод.Картинка = КартинкаQRКода;
//
Функция ДанныеQRКода(QRСтрока, УровеньКоррекции, Размер) 
	
	Отказ = Ложь;
	
	ГенераторQRКода = КомпонентаФормированияQRКода(Отказ);
	Если Отказ Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Попытка
		ДвоичныеДанныеКартинки = ГенераторQRКода.GenerateQRCode(QRСтрока, УровеньКоррекции, Размер);
	Исключение
		ЗаписьЖурналаРегистрации(НСтр("ru = 'Формирование QR-кода'", ),
			УровеньЖурналаРегистрации.Ошибка, , , ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
	КонецПопытки;
	
	Возврат ДвоичныеДанныеКартинки;
	
КонецФункции
#КонецОбласти

Функция ПолучитьФайл(пТаб,Серт,имяФайлаПДФ,строкаQRКода) Экспорт
	
	//пТаб = новый ТабличныйДокумент();
	//пТаб.Прочитать("C:\TEMP\7.mxl");
	//пТаб.автомасштаб = Истина;
	
	Макет = Справочники.СертификатыКлючейЭлектроннойПодписиИШифрования.ПолучитьМакет("Макет");
	Обл = Макет.ПолучитьОбласть("Строка");
	
	Таб = ВставитьРазделитель(пТаб,Обл);
	
	ДанныеQRКода = ДанныеQRКода(строкаQRКода,0,190);
	Обл.Рисунки.QRКод.Картинка = Новый Картинка(ДанныеQRКода);
	
	Обл.Параметры.Заполнить(Серт);
	Обл.Параметры.ДатаПодписания = ""+УниверсальноеВремя(ТекущаяДата()+1)+" UTC";
	
	Обл.Область().СоздатьФорматСтрок();
	Таб.Вывести(Обл);
	
	Таб.Записать(имяФайлаПДФ,ТипФайлаТабличногоДокумента.PDF);
		
	
	
КонецФункции

Функция ВставитьРазделитель(Таб,Обл)
	
	Если Таб.ПроверитьВывод(Обл)=Ложь Тогда
		
		конСтрока = Неопределено;
		Для а=-Таб.ВысотаТаблицы по -1 Цикл
			
			л1 = Таб.Область(-а,3,-а,3).ГраницаСверху;
			л2 = Таб.Область(-а,3,-а,3).ГраницаСнизу;
			
			Если л1.Толщина<>0 и л2.Толщина <> 0 Тогда
				конСтрока = -а-1;
				прервать;
			КонецесЛи;
			
		КонецЦикла;
		
		Если конСтрока <> Неопределено Тогда
			Т1 = Таб.ПолучитьОбласть(1,,конСтрока);
			Т2 = Таб.ПолучитьОбласть(конСтрока+1,,Таб.ВысотаТаблицы);
			Таб.Очистить();
			Таб.Вывести(Т1);
			Таб.ВывестиГоризонтальныйРазделительСтраниц();
			Таб.Вывести(Т2);
		КонецЕсли;
	КонецесЛИ;
	
	Возврат Таб;
	
КонецФункции
