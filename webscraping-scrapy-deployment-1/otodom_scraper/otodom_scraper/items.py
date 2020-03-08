# -*- coding: utf-8 -*-

# Define here the models for your scraped items
#
# See documentation in:
# https://docs.scrapy.org/en/latest/topics/items.html

import scrapy
import re
from scrapy.loader.processors import MapCompose, TakeFirst, Join


def filter_spaces(value):
    return value.strip()


def clean_price(value):
    return ''.join(re.findall('[0-9]+', value))


class AdItem(scrapy.Item):
    item_id = scrapy.Field(
        input_processor=MapCompose(filter_spaces),
        output_processor=TakeFirst(),
    )
    tracking_id = scrapy.Field(
        input_processor=MapCompose(filter_spaces),
        output_processor=TakeFirst(),
    )
    url = scrapy.Field(
        input_processor=MapCompose(filter_spaces),
        output_processor=TakeFirst(),
    )
    featured_name = scrapy.Field(
        input_processor=MapCompose(filter_spaces),
        output_processor=TakeFirst(),
    )
    title = scrapy.Field(
        input_processor=MapCompose(filter_spaces),
        output_processor=TakeFirst(),
    )
    subtitle = scrapy.Field(
        input_processor=MapCompose(filter_spaces),
        output_processor=TakeFirst(),
    )
    rooms = scrapy.Field(
        input_processor=MapCompose(filter_spaces),
        output_processor=TakeFirst(),
    )
    price = scrapy.Field(
        input_processor=MapCompose(clean_price),
        output_processor=TakeFirst(),
    )
    price_per_m = scrapy.Field(
        input_processor=MapCompose(clean_price),
        output_processor=TakeFirst(),
    )
    area = scrapy.Field(
        input_processor=MapCompose(filter_spaces),
        output_processor=TakeFirst(),
    )
    others = scrapy.Field(
        input_processor=MapCompose(filter_spaces),
        output_processor=Join(),
    )
