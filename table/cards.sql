CREATE TABLE "public"."cards" (
  "set" text NOT NULL,
  "collector_number" text NOT NULL,
  "title_id" int4 NOT NULL,
  "en_us" text,
  "pt_br" text,
  "fr_fr" text,
  "it_it" text,
  "de_de" text,
  "es_es" text,
  "ru_ru" text,
  "ja_jp" text,
  "ko_kr" text,
  "isvalid" bool NOT NULL DEFAULT true,
  PRIMARY KEY ("set","collector_number","title_id")
);
