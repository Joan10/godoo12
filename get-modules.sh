#!/bin/bash

## Dependències OCA
temp_root=$(mktemp -d)
git clone https://github.com/OCA/l10n-spain.git -b 12.0 $temp_root # Descarregam els spain addons d'OCA
while read m; do # Descarregam totes les dependències
	tempd=$(mktemp -d)
	git clone https://github.com/OCA/$m -b 12.0 $tempd;
	rsync -rva $tempd/* spain-addons # cada repositori s'ha de moure al directori immediatament inferior ja que sinó no Odoo no els llegeix
	rm -rf $tempd
done<$temp_root/oca_dependencies.txt
rsync -rva $temp_root/* spain-addons # cada repositori s'ha de moure al directori spain-addons ja que sinó no Odoo no els llegeix dins subdirectoris
rm -rf $temp_root

# Eliminam referències a impostos no definits
sed -i -e "/l10n_es.account_tax_template_p_iva10_nd/d" -e "/l10n_es.account_tax_template_p_iva4_nd/d"  ./spain-addons/l10n_es_aeat_mod347/data/tax_code_map_mod347_data.xml
sed -i -e "/l10n_es.account_tax_template_p_iva10_nd/d" -e "/l10n_es.account_tax_template_p_iva4_nd/d"  ./spain-addons/l10n_es_aeat_sii/data/aeat_sii_map_data.xml
sed -i -e "/l10n_es.account_tax_template_p_iva10_nd/d" -e "/l10n_es.account_tax_template_p_iva4_nd/d"  ./spain-addons/l10n_es_vat_book/data/aeat_vat_book_map_data.xml
sed -i -e "/l10n_es.account_tax_template_p_iva10_nd/d" -e "/l10n_es.account_tax_template_p_iva4_nd/d"  ./spain-addons/l10n_es_aeat_mod390/data/tax_code_map_mod390_data.xml

# Dependències extra
while read m; do # Descarregam totes les dependències
	tempd=$(mktemp -d)
        git clone https://github.com/OCA/$m -b 12.0 $tempd;
        rsync -rva $tempd/* spain-addons # cada repositori s'ha de moure al directori immediatament inferior ja que sinó no Odoo no els llegeix
        rm -rf $tempd
done<extra_oca_dependencies.txt
