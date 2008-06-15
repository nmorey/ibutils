#!/bin/awk -f
{
  if (h == 0) {
    print;
  }
}
/[\#]--/{
  h = 1;
  print "*/";
}
/^class/{
  if (h) {
    print "\n\n\n";
    print "//////////////////////////////////////////////////////////////";
    print "//";
    print "// CLASS ", $2;
    print "//";

    if (comment != "") {
      print comment;
    }
    c = $2;
    p = 0;
  }
}
/[^\}];/{
  if (p && h) {
    if (comment != "") {
      print comment;
    }

    for (f = 1; f <= NF; f++) {
      if (f == 2) {
        printf("%s::%s ",c,$f);
      } else {
        printf("%s ",$f);
      }
    }
    print " ";
  }
}
/\/[\*]/{
  m = 1;
  comment = "";
}
{
  if (m && p && h) {
    comment = comment "\n" $0;
  }
}
/[\*]\// {
  m = 0;
}
/public/{
  p = 1;
}
