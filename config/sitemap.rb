SitemapGenerator::Sitemap.default_host = "http://www.claco.com"

SitemapGenerator::Sitemap.create do
  add "/pioneers", :changefreq => 'weekly', :priority => 0.9

  add "/about", :changefreq => 'monthly', :priority => 0.7
  add "/about/team", :changefreq => 'monthly', :priority => 0.7
  add "/apply", :changefreq => 'monthly', :priority => 0.7
  add "/unitedweteach", :changefreq => 'monthly', :priority => 0.3
end