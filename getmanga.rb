require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'pp'
require 'yaml'
require 'uri'
require 'fileutils'

ROOTDOMAIN = 'http://onemanga.com'
USERAGENT = 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_5_2; hu-hu) AppleWebKit/525.13 (KHTML, like Gecko) Version/3.1 Safari/525.13'
ROOTDIR = 'manga'

def downloadImage(folder, url)
    fname = folder+URI.parse(url).path.split('/').last
    content = ''
    retries = 100
    begin
        content = open(url, 'User-Agent' => USERAGENT).read
    rescue => e
        if retries > 0
            retries -= 1
            puts "...sleeping... (#{e.message})"
            sleep 10
            retry
        else
            puts e.message
            return false
        end
    end        
    File.open(fname, 'wb') do |f|
        f.write(content)
    end
    puts fname
end

def getImages(chapterUrl)
    retries = 100
    begin
        doc = Hpricot(open(chapterUrl, 'User-Agent' => USERAGENT))
    rescue => e
        if retries > 0
            retries -= 1
            puts "...sleeping... (#{e.message})"
            sleep 10
            retry
        else
            puts e.message
            return []
        end
    end
    image = doc/"/html/body/div/div[3]/div/div[3]/a/img"
    imagelink = image.attr('src')

    imagelink_base = imagelink.gsub('01.jpg', '')

    images = []
    doc.search("/html/body/div/div[3]/div/div[2]/select[2]/option") do |option|
        val = option.get_attribute('value')
        images << imagelink_base+val+".jpg" if val.to_i > 0
    end
    images
end

def findMangaPages(mangaName)
    mangaPages = []
    doc = Hpricot(open(ROOTDOMAIN+"/#{mangaName}", 'User-Agent' => USERAGENT))
    doc.search('td.ch-subject/a') do |link|
        mangaPages << ROOTDOMAIN+link.get_attribute("href")
    end
    mangaPages
end

mangaimages = {}
findMangaPages("Bleach").each do |mpage|
    puts "Getting #{mpage}"
    dirname = mpage.split('/')[-2..-1].join('/')+"/"
    ilist = getImages(mpage)
    FileUtils.mkdir_p(dirname)
    ilist.each do |url|
        downloadImage(dirname, url)
    end
    puts "done"
end
