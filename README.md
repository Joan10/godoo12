# Introducció

ERP basat en Odoo 12 i adaptat a localització espanyola. Entorn en proves.

# Quickstart

## Construim imatge

```
sudo apt-get install rsync
sudo ./get-modules.sh
sudo docker build -t godoo12:1.0 .
```

## Inicialitzam entorn

```
cp odoo.env.template odoo.env
mkdir pg_data
mkdir odoo_data
mkdir extra-addons
sudo chown -R 999.999 pg_data/
sudo chown -R 101.101 odoo_data/
```

## Arrancam contenidors

```
sudo docker-compose up -d
```

Entram a http://localhost:8009 i cream la base de dades.


## Instal·lam els mòduls de la regió espanyola:

```
cat spain_module_list.txt | sudo ./install-modules.sh -d <<database>> -c godoo12_web -f odoo.env
sudo docker-compose restart
```

## Ajustar paràmetres

Si heu canviat el port per defecte (8069) pel qual accediu a l'Odoo, heu d'anar a l'entorn Web i:

* A la pestanya de l'esquerra: `Configuració -> Activar el mode programador`
* A la pestanya de l'esquerra: `Configuració -> Tècnic -> Paràmetres del sistema`
* Modificar/Afegir el camp `web.base.url` i posar `http://localhost:8069`. 
* Modificar/Afegir el camp `report.url` i posar `http://localhost:8069`. 

Més especificament, s'ha d'afegir una URL a la qual el programa `wkhtmltopdf`, des de dins el container, pugui accedir sense traves. Entenem com a traves SimpleHTTPAuth's, mappings de ports etc. 

Això generalment serà necessari si entrau a través d'un proxy SSL o compartiu al sistema amb altres instàncies d'Odoo.

Si aquest camp no està especificat correctament, no es renderitzaran els PDF com toca.


# Mòduls 

## Descarregar mòduls OCA Spain

L'script `get-modules.sh` descarrega els mòduls d'OCA i les seves dependències.

Els mòduls es descarreguen del gitlab d'OCA. Primer es col·loquen a un directori de mòduls que s'especifica a odoo.conf amb la variable `addons_path`. Hem de descarregar dos conjunts de mòduls:

* Els OCA Spain de `https://github.com/OCA/l10n-spain.git`.
* Les dependències dels mòduls d'OCA Spain de `https://github.com/OCA/`. Els podem trobar al fitxer OCA_requeriments.txt del repositori d'OCA Spain.

Compte, que han d'estar tots els mòduls dins d'un mateix directori, sense subdirectoris. Alguns mòduls d'OCA es troben dins subdirectoris i s'han de moure o Odoo no els troba.

## Descarregar altres mòduls bàsics

L'script `get-modules.sh` descarrega també els mòduls especificats al fitxer extra_oca_dependencies.txt i totes les seves dependències.

## Instal·lar mòduls

Els mòduls descarregats han d'instal·lar-se a cada Base de Dades de l'Odoo. Això pot fer-se via web o mitjançant l'script `install-modules.sh`.

## Actualitzar mòduls

!!! Aquest procediment és complicat i pot donar problemes !!!
Feu la prova abans en un entorn segur.

Per això cal refer la imatge de Docker. Passes:

1. Refeim el directori d'addons:
```
sudo mv spain-addons{,.old} # el podem esborrar també
sudo mkdir spain-addons
```
2. Descarregam de nou els mòduls:

```
sudo ./get-modules.sh
```
3. Refeim la imatge de Docker i tornam a arrancar:

```
sudo docker build -t godoo12:1.0 .
sudo docker-compose down
sudo docker-compose up
```
4. Amb l'script `install-modules.sh` podem actualitzar els mòduls.

```
cat spain_module_list.txt | sudo ./install-modules.sh -d <<database>> -c godoo12_web -f odoo.env
```

Compte, que així només actualitzarem els de la llista. Els altres que hem instal·lat ho hem de fer des del web. Ho podem fer amb l'interfície web un per un anant a Aplicacions -> Actualitzacions o bé a Aplicacions -> Aplicacions i seleccionar cada aplicació per separat.

## Instal·lar altres mòduls sense refer la imatge

La carpeta extra-addons s'exporta amb el Docker Compose i permet afegir mòduls sense refer la imatge. 

1. Copiar mòdul a carpeta extra-addons.
1. Reiniciar server: `docker-compose restart`
1. Actualitzar llista de mòduls a la web o amb la utilitat install-modules.sh. P. ex: 
```
cat<<EOF|sudo ./install-modules.sh -d <<database>> -c godoo12_web -f odoo.env
modul1
modul2
modul3
EOF
```

# Backups
## Generar Backup

És suficient amb generar un backup de:

1. La base de dades:
```
sudo docker exec -t godoo12_db pg_dumpall -c -U dbu_odoo | gzip -c > bck_db_godoo12.sql.gz
```
i per si de cas:
```
tar cvzf bck_pgdata_godoo12.tar.gz pg_data/
```
1. Els mòduls i les dades:
```
tar cvzf bck_data_godoo12.tar.gz spain-addons/ extra-addons/ odoo_data/
```
1. Els fitxer de contrasenyes
```
zip -r bck_odoo12.env.zip odoo.env -P <contrasenya>
```


## Restaurar Backup


1. `unzip bck_odoo12.env.zip`
1. Copiam els fitxers i directoris:
```
tar xvzf bck_data_godoo12.tar.gz
```
1. Restauram directoris i permisos:
```
sudo chown -R 101.101 odoo_data/
mkdir pg_data
sudo chown -R 999.999 pg_data/
```
1. `sudo docker-compose up -d`
1. Restauram la base de dades:
```
gunzip bck_db_godoo12.sql.gz
sudo docker cp bck_db_godoo12.sql godoo12_db:/tmp
sudo docker exec -t godoo12_db psql --username=dbu_odoo -f /tmp/bck_db_godoo12.sql postgres
```
1. `sudo docker-compose restart`



# Errors trobats

## Xurro error python sobre iva10nd

Resulta que alguns mòduls fan referència a un impost que no està definit. No té sentit que hi siguin. Com a workaround, simplement s'elimina del fitxer.

```
odoo.tools.convert.ParseError: "<class 'ValueError'>: "External ID not found in the system: l10n_es.account_tax_template_p_iva10_nd" while evaluating
```

Els mòduls amb impostos no existents són:

```
./l10n_es_aeat_sii/data/aeat_sii_map_data.xml
./l10n_es_vat_book/data/aeat_vat_book_map_data.xml
./l10n_es_aeat_mod390/data/tax_code_map_mod390_data.xml
./l10n_es_aeat_mod347/data/tax_code_map_mod347_data.xml
```

