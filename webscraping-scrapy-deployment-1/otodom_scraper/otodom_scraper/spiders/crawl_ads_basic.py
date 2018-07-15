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
    selected_type_2 = settings.get('type_2_id', 0)
    selected_voivodeship_id = settings.get('voivodeship_id', 0)

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

            link = None
            if ad.css("::attr('data-url')").extract():
                link = ad.css("::attr('data-url')").extract()[0].strip()

            item_id = None
            if ad.css("::attr('data-item-id')").extract():
                item_id = ad.css("::attr('data-item-id')").extract()[0].strip()

            tracking_id = None
            if ad.css("::attr('data-tracking-id')").extract():
                tracking_id = ad.css("::attr('data-tracking-id')").extract()[0].strip()

            featured_name = None
            if ad.css("::attr('data-featured-name')").extract():
                featured_name = ad.css("::attr('data-featured-name')").extract()[0].strip()

            title = None
            if ad.css(".offer-item-title ::text").extract():
                title = ad.css(".offer-item-title ::text").extract()[0]

            subtitle = None
            if ad.css(".offer-item-header p ::text").extract():
                subtitle = ad.css(".offer-item-header p ::text").extract()[0].strip()

            rooms = None
            if ad.css(".offer-item-rooms ::text").extract():
                rooms = ad.css(".offer-item-rooms ::text").extract()[0].strip()

            price = None
            if ad.css(".offer-item-price ::text").extract():
                price = ad.css(".offer-item-price ::text").extract()[0].strip()

            price_per_m = None
            if ad.css(".offer-item-price-per-m ::text").extract():
                price_per_m = ad.css(".offer-item-price-per-m ::text").extract()[0].strip()

            area = None
            if ad.css(".offer-item-area ::text").extract():
                area = ad.css(".offer-item-area ::text").extract()[0].strip()

            others = None
            if ad.css(".params-small li ::text").extract():
                others = [x.strip() for x in ad.css(".params-small li ::text").extract()]

            i = {}
            i['type_1'] = self.type_1[self.selected_type_1]
            i['type_2'] = self.type_2[self.selected_type_2]
            i['voivodeship'] = self.voivodeships[self.selected_voivodeship_id]
            i['item_id'] = item_id
            i['tracking_id'] = tracking_id
            i['link'] = link
            i['featured_name'] = featured_name
            i['title'] = title
            i['subtitle'] = subtitle
            i['rooms'] = rooms
            i['price'] = price
            i['price_per_m'] = price_per_m
            i['area'] = area
            i['others'] = others

            yield i
