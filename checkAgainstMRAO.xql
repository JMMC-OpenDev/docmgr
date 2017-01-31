xquery version "3.0";

(: 
curl -s http://www.mrao.cam.ac.uk/projects/OAS/publications/bib/web_optint_refereed.bib | grep @article | while read line; do a=${line#@article{}; echo ${a%,}; done|while read bibcode; do echo "<bibcode>$bibcode</bibcode>"; done|sed "s/\&/\&amp;/g"
:)

let $cav := <bibcodes>
    <bibcode>1986Natur.320..595B</bibcode>
<bibcode>1996A&amp;A...306L..13B</bibcode>
<bibcode>1997MNRAS.290L..11B</bibcode>
<bibcode>1998MNRAS.297..462B</bibcode>
<bibcode>1988MNRAS.235.1203B</bibcode>
<bibcode>1990MNRAS.245p...7B</bibcode>
<bibcode>1993JOSAA..10.1882B</bibcode>
<bibcode>1991AJ....102.2066G</bibcode>
<bibcode>1990AJ....100..294G</bibcode>
<bibcode>1992AJ....103..953G</bibcode>
<bibcode>1987Natur.328..694H</bibcode>
<bibcode>1989MNRAS.241p..51H</bibcode>
<bibcode>1991JOSAA...8..134H</bibcode>
<bibcode>1992JOSAA...9..203H</bibcode>
<bibcode>1992AJ....103.1662H</bibcode>
<bibcode>1994PASP..106.1003H</bibcode>
<bibcode>1995MNRAS.276..640H</bibcode>
<bibcode>A&amp;A...334L...5H</bibcode>
<bibcode>1995JOSAA..12..366L</bibcode>
<bibcode>1996ApOpt..35.5122L</bibcode>
<bibcode>1996ApOpt..35..612L</bibcode>
<bibcode>1998ApOpt..37.8129L</bibcode>
<bibcode>1993PASP..105..509N</bibcode>
<bibcode>1991MNRAS.251..155N</bibcode>
<bibcode>1994MNRAS.266..745T</bibcode>
<bibcode>1995MNRAS.277.1541T</bibcode>
<bibcode>1997MNRAS.285..529T</bibcode>
<bibcode>1992MNRAS.257..369W</bibcode>
<bibcode>1997MNRAS.291..819W</bibcode>
<bibcode>1999MNRAS.306..353T</bibcode>
<bibcode>2000MNRAS.318..381Y</bibcode>
<bibcode>2000MNRAS.315..635Y</bibcode>
<bibcode>1999MNRAS.304..218L</bibcode>
<bibcode>1997MNRAS.290...66S</bibcode>
<bibcode>1999MNRAS.309..379W</bibcode>
<bibcode>2002RSPTA.360..969B</bibcode>
<bibcode>2001MNRAS.327..217H</bibcode>
<bibcode>1999ApJ...512..351M</bibcode>
<bibcode>2000PASP..112..555T</bibcode>
<bibcode>2002A&amp;A...387L..21T</bibcode>
<bibcode>2001MNRAS.326.1381K</bibcode>
<bibcode>2004MNRAS.347.1187B</bibcode>
<bibcode>2004MNRAS.349..303J</bibcode>
<bibcode>2005MNRAS.356.1362D</bibcode>
<bibcode>2005MNRAS.357..656B</bibcode>
<bibcode>2003AJ....126.2502M</bibcode>
<bibcode>2005PASP..117.1255P</bibcode>
<bibcode>2006MNRAS.370..884T</bibcode>
<bibcode>2007NewAR..51..565H</bibcode>
<bibcode>2007NewAR..51..583H</bibcode>
<bibcode>2009PASP..121...45B</bibcode>
<bibcode>2010MeScT..21e5201B</bibcode>
<bibcode>2012A&amp;A...541A..46G</bibcode>
<bibcode>2012A&amp;A...539A..89B</bibcode>
<bibcode>2012A&amp;ARv..20...53B</bibcode>
<bibcode>2012MNRAS.422.2560S</bibcode>
</bibcodes>
let $olbin := doc("http://jmmc.fr/bibdb/xml")//bibcode
let $missing := distinct-values($cav//bibcode[not(.=$olbin)])
return string-join(for $e in $missing return "http://adsabs.harvard.edu/abs/"||$e, "&#13;&#10;")