#!/bin/bash

# Script to scrap the data of lost items from intercity.pl website
# Since website requires to accept cookies `curl` command may need
# some attention. Variable 'N' also needs to be adjusted manually.

# Set the input HTML file and the output CSV file
input_file="tmp.html"
output_file="table.csv"
[ -f ./$output_file ] && mv ./$output_file "./${output_file}.old"
rm ./$output_file

# the size of the table on the webiste
# it has to be adjusted automatically
N=481

for j in $(seq 1 $N);
do
  # Show the progress
  echo -ne "$j/$N\r"

  # Get the raw html
  curl "https://www.intercity.pl/pl/site/dla-pasazera/obsluga-klientow/odbior-zagubionego-bagazu.html?page=$j" \
    -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' \
    -H 'accept-language: pl-PL,pl;q=0.9' \
    -H 'cache-control: max-age=0' \
    -H 'cookie: latlng=null; PHPSESSID=569d8r6gg11l6hp515c4rqrqgr; akaalb_www-intercity-pl-production=~op=www_intercity_pl:pdc-www-intercity-pl|~rv=53~m=pdc-www-intercity-pl:0|~os=c95b93939f9892ac73b94fbc3cf54eb3~id=6bef2f7d9a0bbe1413ed0bf4516156f9; screenw=1536; screenh=733; ak_bmsc=32468D931815013102533CE4A6026AE4~000000000000000000000000000000~YAAQY9U+F+fciSWRAQAAA1oMVxgA/YqhmODBMOLI0liBazA4JengUUydHwcclYBdVr27M6EGZ3WAMEq7UIysJU8ChuQtMmc+drCzBnLeTcB6W0EVljBBT8zcxN1qwkAokUcG948AlwmjeC7KnsBOW25Ryno8l9piRTX9IZQV4CcZJiLpND+a+uVXJ9tRhcGHqutRCrkEQSh+zzPL+oOoW+8y122prAlCaFf1TfRVM3zBPzjOMmq3qg/Z7qB21VglgTDZpU/7qjw1+MzbPkGSnwYnyuDtL9oz1rn4TqwEK9T2qYnl1Ss8POuglrl7meE4kiFSRrmNN/RmUZuHQBDjBgjhfy1Xb+8kVyVuz/RUwXSWMwtY4rkm89kqS3x8kuw38rmup37KCsebLNSjZOJnIeSkq03KQg4QRJkBcdsly+I6c49bGiX5ReHPa6IV2tIroxmFLfH518xNWBYy2b6A; _ga_GWRR62WJG2=GS1.1.1723742312.1.0.1723742325.47.0.0; CookieConsent={stamp:%27PqFu93GxIEbxDFC7lRBZTzVrS59mNL5hNkJMfwPUmOemYL4+MNwG/A==%27%2Cnecessary:true%2Cpreferences:false%2Cstatistics:false%2Cmarketing:false%2Cmethod:%27explicit%27%2Cver:1%2Cutc:1723742329856%2Cregion:%27pl%27}; bm_sv=CD69B1C29630CC176FCD6D678758BC0D~YAAQY9U+F/MCiiWRAQAADbsMVxiKqlZkeI5cLjzqIhNqmmHzQ53r13w3mIW5rRhTalRB6a7aDpI/RHTQfhSvd1RtUu097yBhmHDaohWPB5fP2MXX6ZNTk/YyCUsML0k8uhkGI2G8d9tpgCXPB8DlejKK7fTp/UvNDrNmEwrpeec8An6mw8CBVCRx9Ra6LKq0zcXkOQHsIHitYou6KyMRRsl/R9+h5jkSYja04Az3rITlG9Wobo6f1+dXdx3+yxZihM4=~1' \
    -H 'dnt: 1' \
    -H 'priority: u=0, i' \
    -H 'sec-ch-ua: "Not)A;Brand";v="99", "Google Chrome";v="127", "Chromium";v="127"' \
    -H 'sec-ch-ua-mobile: ?0' \
    -H 'sec-ch-ua-platform: "Linux"' \
    -H 'sec-fetch-dest: document' \
    -H 'sec-fetch-mode: navigate' \
    -H 'sec-fetch-site: none' \
    -H 'sec-fetch-user: ?1' \
    -H 'upgrade-insecure-requests: 1' \
    -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36' -s > $input_file

  # Extract the relevant table and convert it to CSV
  awk '
  BEGIN { RS = "<tr>|</tr>"; FS = "<td>|</td>" }
  /<h2>Wykaz rzeczy znalezionych<\/h2>/,/<\/table>/ {
  # Check if the current record is within the table body
  if ($0 ~ /<tbody>/) { in_body = 1 }
    if ($0 ~ /<\/tbody>/) { in_body = 0 }

        # Process only if we are within the table body
        if (in_body && $0 ~ /<td>/) {
          row = ""
          for (i = 2; i < NF; i+=2) {
            # Clean the data by removing any remaining HTML tags
            gsub(/<\/?[^>]+>/, "", $i)
            # Trim leading and trailing whitespace
            gsub(/^[ \t]+|[ \t]+$/, "", $i)
            # Concatenate each column separated by a comma
            row = row (row == "" ? "" : ",") $i
          }
          # Print the row, separating each row by a newline
          print row
        }
  }
  ' $input_file | grep -v '^$' >> $output_file # append to the output file
done
