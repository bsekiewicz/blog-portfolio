# -*- coding: utf-8 -*-
import scrapy
from scrapy.linkextractors import LinkExtractor
from scrapy.spiders import CrawlSpider, Rule
from scrapy.conf import settings


class CrawlAdsBasicSpider(CrawlSpider):
    name = 'crawl_ads_basic'

    # parameters definition
    type_1 = ['sprzedaz',
              'wynajem']
    type_2 = ['', # all
              'mieszkanie',
              'dom',
              'pokoj',
              'dzialka',
              'lokal',
              'haleimagazyny',
              'garaz']
    voivodeships = ['', # all
                    'dolnoslaskie',
                    'kujawsko-pomorskie',
                    'lubelskie',
                    'lubuskie',
                    'mazowieckie',
                    'malopolskie',
                    'opolskie',
                    'podkarpackie',
                    'podlaskie',
                    'pomorskie',
                    'warminsko-mazurskie',
                    'wielkopolskie',
                    'zachodniopomorskie',
                    'lodzkie',
                    'slaskie',
                    'swietokrzyskie']

    selected_type_1 = settings.get('type_1_id', 0)
    selected_type_2 = settings.get('type_2_id', 2)
    selected_voivodeship_id = settings.get('voivodeship_id', 6)

    allowed_domains = ['www.otodom.pl']
    start_urls = ['https://www.otodom.pl/' +
                  type_1[selected_type_1] + '/' +
                  type_2[selected_type_2] + '/' +
                  voivodeships[selected_voivodeship_id] +
                  '?nrAdsPerPage=72&page=1']

    # crawl all pages ends with page=NUMBER
    rules = (
        Rule(LinkExtractor(allow=(type_1[selected_type_1] + '/' +
                                  type_2[selected_type_2] + '/' +
                                  voivodeships[selected_voivodeship_id] +
                                  '.*page=[0-9]+$').replace('//', '/')),
             callback='parse_item', follow=True),
    )

    def parse_item(self, response):

        # for each ad in page (promo and no promo)
        for ad in response.css('.col-md-content article'):

            url = ad.css("::attr('data-url')").extract()
            if url:
                url = url[0].strip()

            item_id = ad.css("::attr('data-item-id')").extract()
            if item_id:
                item_id = item_id[0].strip()

            tracking_id = ad.css("::attr('data-tracking-id')").extract()
            if tracking_id:
                tracking_id = tracking_id[0].strip()

            featured_name = ad.css("::attr('data-featured-name')").extract()
            if featured_name:
                featured_name = featured_name[0].strip()

            title = ad.css(".offer-item-title ::text").extract()
            if title:
                title = title[0].strip()

            subtitle = ad.css(".offer-item-header p ::text").extract()
            if subtitle:
                subtitle = subtitle[0].strip()

            rooms = ad.css(".offer-item-rooms ::text").extract()
            if rooms:
                rooms = rooms[0].strip()

            price = ad.css(".offer-item-price ::text").extract()
            if price:
                price = price[0].strip()

            price_per_m = ad.css(".offer-item-price-per-m ::text").extract()
            if price_per_m:
                price_per_m = price_per_m[0].strip()

            area = ad.css(".offer-item-area ::text").extract()
            if area:
                area = area[0].strip()

            others = ad.css(".params-small li ::text").extract()
            if others:
                others = [x.strip() for x in others]

            i = {}
            i['type_1'] = self.type_1[self.selected_type_1]
            i['type_2'] = self.type_2[self.selected_type_2]
            i['voivodeship'] = self.voivodeships[self.selected_voivodeship_id]
            i['item_id'] = item_id
            i['tracking_id'] = tracking_id
            i['url'] = url
            i['url_ref'] = response.url
            i['featured_name'] = featured_name
            i['title'] = title
            i['subtitle'] = subtitle
            i['rooms'] = rooms
            i['price'] = price
            i['price_per_m'] = price_per_m
            i['area'] = area
            i['others'] = others
            yield i
