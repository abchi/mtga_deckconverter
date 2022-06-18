CREATE TABLE "public"."card_m" (
  "set" text NOT NULL,
  "collector_number" text NOT NULL,
  "title_id" int4 NOT NULL,
  "text_en" text,
  "text_fr" text,
  "text_it" text,
  "text_de" text,
  "text_es" text,
  "text_ja" text,
  "text_pt" text,
  "text_ru" text,
  "text_ko" text,
  "isvalid" int4 NOT NULL DEFAULT 1,
  PRIMARY KEY ("set","collector_number","title_id")
);
