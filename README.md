
Nothing interesting here for your but  usefull for me script that scan
html for instagram images and download  them. I have no instagram, but
want to spy for someone.

# Install how-to

```bash
# git clone and cd..
# install perl dependencies, below used "carton"
carton install

export MANDRILL=1234567890
carton exec ./inst_spy.pl --word https://downtownie.wordpress.com \
                          --out  ~/spy/ \
                          --email mailbox@example.com
# Now you can serve some http "~/spy"
# For example install "npm install -g http-server"
http-server ~/spy
```

# Man


```
NAME
    inst_spy.pl - Instagram image fetcher

SYNOPSIS
      inst_spy.pl [ --help | --manual] [options] --output DIR

      Help Options:
       --help      Show this scripts help information.
       --manual    Read this scripts manual.
       --output    Where to download img/ and maria.json data file
       --wordpress Url to site that contains instagram urls
       --email     Email for notify. You should set mandrill api key in env MANDRILL then
       --from      email from, default noreply@nowhere.com

      Example:

      export MANDRILL=1234567890
      ./inst_spy.pl --word https://downtownie.wordpress.com \
                    --out  ~/spy/ \
                    --email mailbox@example.com

OPTIONS
    --help  Show the brief help information.

    --manual
            Read the manual.

    --output
            This script build maria.json - data about all images fetched
            before. And download images into "img" subdir of --output dir. All
            instagram images from url set by --wordpress will be appended to
            maria.json.

    --wordpress
            Url to scan. Why switcher is called wordpress? Because it used to
            scan wordpress page.

DESCRIPTION
    Scan site for instagram images, download them, save meta into maria.json.

Why?
    Some instagram accounts are hidden. But someone may be used in wordpress
    plugin, to share some latest images. I have no instagram account, but want
    to be notified about new picture :). So this script fetch them and send to
    my email notify.
```
