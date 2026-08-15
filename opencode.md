Caso 3 – Teleinformática: Metabase + MySQL sobre Kubernetes

Necesito completar un trabajo práctico de Teleinformática desplegando Metabase y MySQL 8 sobre Kubernetes, reutilizando el mismo dataset google-mobility.sql.gz que utilicé anteriormente en un despliegue con OpenStack.

Quiero que trabajes conmigo PASO A PASO y que no destruyas ni recrees recursos que ya existen.

1. Objetivo general

Construir una arquitectura Cloud Native con:

Kubernetes

Rancher

Docker / imágenes de contenedores

MySQL 8

Metabase

Ingress NGINX

Longhorn para almacenamiento persistente

El objetivo final es:

Ejecutar MySQL 8 dentro de Kubernetes.

Tener almacenamiento persistente mediante Longhorn.

Importar el dataset google-mobility.sql.gz.

Ejecutar Metabase.

Conectar Metabase con MySQL.

Consultar el dataset Google Mobility desde Metabase.

Crear gráficos y dashboard.

Exponer Metabase mediante Ingress NGINX.

Comprobar persistencia.

Documentar todo el proceso para el informe.

2. Estado actual

NO estamos comenzando totalmente desde cero.

Ya existe una VM preparada para trabajar con Kubernetes.

Acceso:

ssh ubuntu@10.201.2.37


Dentro de esa VM ya se configuró Rancher y kubectl.

Ya existe:

Rancher Project: fequirogaa-project
Namespace: fequirogaa-dev


El namespace activo es:

fequirogaa-dev


También se generó:

~/.kube/config


Por lo tanto:

NO crear nuevamente el Project.

NO crear nuevamente el Namespace salvo que se compruebe que desaparecieron.

NO ejecutar nuevamente el procedimiento inicial de Rancher sin necesidad.

3. Seguridad importante

Durante la configuración inicial se utilizó un Bearer Token de Rancher.

Ese token NO debe:

guardarse en Git;

aparecer en README;

aparecer en manifiestos YAML;

aparecer en capturas;

escribirse en documentación.

Si se encuentra una credencial real dentro del repositorio, avisarme antes de continuar.

No imprimir Secrets en texto plano.

4. Arquitectura objetivo

La arquitectura debe quedar aproximadamente así:

                         Usuario
                            |
                            v
                      Ingress NGINX
                            |
                            v
                    Service Metabase
                            |
                            v
                  Deployment Metabase
                            |
                            |
                     mysql-service:3306
                            |
                            v
                     Service MySQL
                            |
                            v
                   StatefulSet MySQL 8
                            |
                            v
                           PVC
                            |
                            v
                        Longhorn
                            |
                            v
                 almacenamiento persistente


Todo lo creado para el TP debe quedar dentro de:

fequirogaa-dev


5. Recursos Kubernetes necesarios

El proyecto debe contener como mínimo:

Namespace existente: fequirogaa-dev

Secret

PersistentVolumeClaim

StatefulSet MySQL

Service MySQL

Deployment Metabase

Service Metabase

Ingress

almacenamiento Longhorn

6. Estructura sugerida del repositorio

Crear una estructura ordenada, por ejemplo:

Caso3-Tele/
├── k8s/
│   ├── secret.yaml
│   ├── mysql-pvc.yaml
│   ├── mysql-service.yaml
│   ├── mysql-statefulset.yaml
│   ├── metabase-deployment.yaml
│   ├── metabase-service.yaml
│   └── ingress.yaml
│
├── data/
│   └── google-mobility.sql.gz
│
├── README.md
└── .gitignore


No es necesario crear namespace.yaml porque fequirogaa-dev ya existe, salvo que posteriormente quiera documentarlo como código.

7. PRIMERA ETAPA – comprobar el cluster

Antes de crear cualquier recurso nuevo, verificar:

kubectl config current-context


kubectl config view --minify


kubectl get nodes -o wide


kubectl get pods


kubectl get storageclass


kubectl get ingressclass


kubectl get pods -A


También comprobar específicamente:

kubectl get pods -A | grep -Ei 'longhorn|ingress|rancher'


Objetivo:

determinar qué recursos del cluster ya existen.

NO instalar Longhorn ni Ingress NGINX si ya están instalados.

8. Namespace

El namespace del trabajo es:

fequirogaa-dev


Verificar:

kubectl get namespace fequirogaa-dev


Y:

kubectl config view --minify | grep namespace


Todos los recursos propios deben quedar allí.

Cuando sea conveniente utilizar explícitamente:

-n fequirogaa-dev


9. Longhorn

El almacenamiento persistente de MySQL debe utilizar Longhorn.

Primero comprobar:

kubectl get storageclass


Identificar el StorageClass de Longhorn.

NO asumir que se llama exactamente longhorn.

Usar el nombre real que exista en el cluster.

10. Secret de MySQL

Crear un Secret para almacenar como mínimo:

contraseña root MySQL;

nombre de la base;

usuario de aplicación;

contraseña del usuario.

Por ejemplo conceptualmente:

MYSQL_ROOT_PASSWORD
MYSQL_DATABASE
MYSQL_USER
MYSQL_PASSWORD


No hardcodear las contraseñas en el StatefulSet.

No subir contraseñas reales a Git.

Se puede:

utilizar un YAML local ignorado por Git;

crear el Secret mediante kubectl;

mantener un secret.example.yaml con valores ficticios.

11. PVC de MySQL

Crear un PersistentVolumeClaim para MySQL.

Debe utilizar Longhorn.

Ejemplo conceptual:

mysql-pvc


Debe solicitar una capacidad razonable para el TP.

Después aplicar y comprobar:

kubectl get pvc -n fequirogaa-dev


El PVC debe terminar en:

Bound


No continuar con MySQL hasta confirmar esto.

12. MySQL Service

Crear un Service interno para MySQL.

Nombre recomendado:

mysql-service


Puerto:

3306


No debe exponerse públicamente.

Metabase debe poder conectarse utilizando DNS interno:

mysql-service


o:

mysql-service.fequirogaa-dev.svc.cluster.local


Preferir el nombre corto dentro del mismo namespace.

13. MySQL StatefulSet

MySQL debe desplegarse como:

StatefulSet


y no Deployment.

Usar:

MySQL 8


El StatefulSet debe:

utilizar la imagen de MySQL 8;

leer las credenciales desde Secret;

montar el PVC;

exponer el puerto 3306;

tener labels coherentes con el Service;

mantener persistencia aunque el Pod sea recreado.

Después aplicar:

kubectl apply -f ...


Comprobar:

kubectl get statefulset -n fequirogaa-dev


kubectl get pods -n fequirogaa-dev


kubectl logs <mysql-pod> -n fequirogaa-dev


No continuar hasta que MySQL esté:

Running
Ready


14. Verificación de MySQL

Comprobar que se pueda entrar al servidor:

kubectl exec -it <mysql-pod> -n fequirogaa-dev -- mysql ...


Verificar:

SHOW DATABASES;


Después comprobar:

SELECT VERSION();


La versión debe corresponder a MySQL 8.

15. Dataset Google Mobility

El dataset del TP es:

google-mobility.sql.gz


Es exactamente el dataset usado anteriormente en el Caso 2.

Antes de importar, localizarlo.

NO asumir que el archivo ya está en la VM Kubernetes.

Puede estar:

en mi PC;

en el repositorio Caso2;

en otra carpeta;

o todavía necesitar ser copiado.

Primero localizar:

find ~ -name 'google-mobility.sql.gz' 2>/dev/null


Si está solamente en mi computadora local, indicarme cómo copiarlo a:

ubuntu@10.201.2.138


por SCP.

Ejemplo conceptual:

scp google-mobility.sql.gz ubuntu@10.201.2.138:...


No ejecutar una ruta inventada.

16. Importación del dataset

Una vez que MySQL esté funcionando, importar:

google-mobility.sql.gz


Preferir un método simple.

Puede utilizarse:

gunzip -c ...


y enviar el SQL a MySQL mediante kubectl exec.

No descomprimir permanentemente el archivo si no es necesario.

Después verificar:

SHOW DATABASES;


USE <base>;
SHOW TABLES;


Y ejecutar:

SELECT COUNT(*) FROM <tabla_principal>;


Necesitamos evidencia real de que los registros fueron importados.

17. Persistencia

MySQL debe usar:

PVC → Longhorn


Los datos importados no deben desaparecer cuando el Pod sea recreado.

Más adelante se realizará una prueba controlada:

comprobar número de registros;

eliminar solamente el Pod de MySQL;

dejar que StatefulSet lo recree;

volver a consultar los datos;

comprobar que siguen existiendo.

IMPORTANTE:

NO borrar:

PVC
PV
StatefulSet
Namespace


durante esa prueba.

18. Metabase Deployment

Crear:

metabase-deployment.yaml


Metabase debe desplegarse mediante:

Deployment


Usar una imagen oficial de Metabase.

Metabase escucha en:

3000


Primero crear una réplica estable.

Luego, si el práctico necesita demostrar disponibilidad, se puede evaluar aumentar réplicas.

No hacerlo automáticamente sin verificar cómo se persiste la configuración interna de Metabase.

19. Base interna de Metabase vs dataset

No confundir estas dos cosas.

Metabase tiene su propia base interna donde guarda:

usuarios;

dashboards;

preguntas;

configuraciones.

Y además debe conectarse al dataset:

Google Mobility


almacenado en MySQL.

Son conceptos distintos.

Analizar la solución correcta antes de configurar variables de Metabase.

20. Metabase Service

Crear un Service interno:

metabase-service


Debe apuntar al Deployment de Metabase.

Puerto de destino:

3000


Primero verificar Metabase internamente antes de configurar Ingress.

21. Probar Metabase antes del Ingress

Utilizar temporalmente:

kubectl port-forward


Por ejemplo sobre el Service de Metabase.

Verificar desde navegador que aparezca Metabase.

No crear Ingress hasta saber que:

Pod Metabase
+
Service Metabase


funcionan correctamente.

22. Conectar Metabase con MySQL

Dentro de Metabase agregar la base de datos Google Mobility.

Host:

mysql-service


Puerto:

3306


Base:

la base donde se importó Google Mobility.

Usuario:

el usuario configurado para Metabase.

Contraseña:

la correspondiente.

Verificar que Metabase pueda descubrir las tablas.

23. Datos Google Mobility

El dataset contiene métricas relacionadas con cambios porcentuales de movilidad.

Campos utilizados anteriormente incluyen:

grocery_and_pharmacy_percent_change_from_baseline
parks_percent_change_from_baseline
workplaces_percent_change_from_baseline
retail_and_recreation_percent_change_from_baseline
residential_percent_change_from_baseline


También se utilizaron campos geográficos y temporales como:

sub_region_1
sub_region_2
date


24. Visualización que necesito reproducir

Crear una pregunta/gráfico basado en Google Mobility.

Debe poder tener filtros como:

Sub region 1
Sub region 2
Fecha desde
Fecha hasta


Ejemplo utilizado anteriormente:

Sub region 1:
Mendoza Province

Sub region 2:
Capital Department

Fecha desde:
01/01/2020

Fecha hasta:
31/12/2020


El gráfico puede mostrar simultáneamente:

grocery_and_pharmacy
parks
workplaces
retail_and_recreation


como variación porcentual respecto del baseline.

No utilizar como resultado el dashboard demo de Metabase.

El dashboard final debe estar basado en nuestro dataset.

25. Ingress NGINX

Antes de crear el Ingress:

kubectl get ingressclass


Identificar el ingressClassName real.

Comprobar también:

kubectl get pods -A | grep -i ingress


Después crear:

ingress.yaml


Flujo:

Usuario
   |
Ingress NGINX
   |
metabase-service
   |
Metabase :3000


No exponer MySQL mediante Ingress.

26. Acceso externo

Determinar cómo este cluster publica los Ingress.

No asumir hostname o IP.

Inspeccionar:

kubectl get ingress -n fequirogaa-dev


kubectl describe ingress <nombre> -n fequirogaa-dev


y los Services del Ingress Controller si fuera necesario.

El agente debe determinar el mecanismo real utilizado por el laboratorio.

27. Rancher

Rancher se utilizará para visualizar:

Project;

Namespace;

Workloads;

Pods;

StatefulSets;

Deployments;

Services;

Secrets;

PVC;

Ingress;

eventos;

estado general del cluster.

No modificar componentes globales desde Rancher sin necesidad.

28. Docker

No es necesario construir imágenes Docker propias salvo que aparezca un requisito.

Preferir imágenes oficiales:

mysql:8
metabase/metabase


Docker forma parte del concepto de contenerización del práctico, pero Kubernetes administra los workloads.

29. Comandos de diagnóstico

Ante cualquier error NO cambiar YAML al azar.

Utilizar primero:

kubectl get pods -n fequirogaa-dev


kubectl describe pod <pod> -n fequirogaa-dev


kubectl logs <pod> -n fequirogaa-dev


kubectl get events -n fequirogaa-dev --sort-by=.lastTimestamp


kubectl describe pvc <pvc> -n fequirogaa-dev


kubectl describe ingress <ingress> -n fequirogaa-dev


Después explicar:

qué está fallando;

por qué;

cuál es el cambio mínimo;

qué archivo modificar;

cómo verificar la solución.

30. Método de trabajo obligatorio

Trabajar conmigo paso a paso.

NO generar todos los archivos y ejecutarlos automáticamente de una sola vez.

Para cada etapa:

inspeccionar el estado actual;

explicarme qué se va a hacer;

mostrar el YAML o comando;

aplicarlo;

verificar;

revisar errores;

recién entonces continuar.

Por ejemplo:

Secret
↓
verificación
↓
PVC
↓
verificación
↓
MySQL Service
↓
verificación
↓
MySQL StatefulSet
↓
verificación


31. No realizar acciones destructivas automáticamente

NO ejecutar sin consultarme:

kubectl delete namespace


kubectl delete pvc


kubectl delete pv


ni ningún borrado masivo.

Tampoco utilizar:

kubectl delete -f .


sin explicarme exactamente qué desaparecerá.

Si existe un error, intentar corregir el recurso en lugar de destruir toda la infraestructura.

32. Git

El repositorio debe quedar limpio.

Crear .gitignore.

No subir:

kubeconfig
tokens
contraseñas
certificados
claves privadas
Secrets reales


Sí subir:

manifiestos YAML
README
documentación
secret.example.yaml


con valores ficticios cuando corresponda.

33. Evidencias para el informe

Durante todo el trabajo necesito capturas.

Cuando lleguemos a un punto importante, avisarme:

CAPTURA PARA EL INFORME


Necesito documentar al menos:

acceso a la VM Kubernetes;

contexto Kubernetes;

Project Rancher;

namespace fequirogaa-dev;

Nodes;

StorageClass Longhorn;

Secret existente sin revelar datos;

PVC Bound;

StatefulSet MySQL;

Pod MySQL Running;

Service MySQL;

MySQL 8 funcionando;

dataset Google Mobility importado;

cantidad de registros;

Deployment Metabase;

Pod Metabase Running;

Service Metabase;

conexión Metabase → MySQL;

Ingress;

acceso desde navegador;

gráfico Google Mobility;

dashboard;

prueba de persistencia.

Para cada captura explicarme brevemente qué demuestra.

34. Resultado final esperado

Al ejecutar:

kubectl get all -n fequirogaa-dev


deberíamos encontrar como mínimo:

Pod MySQL
StatefulSet MySQL
Service MySQL

Pod Metabase
Deployment Metabase
Service Metabase


También:

kubectl get pvc -n fequirogaa-dev


debe mostrar:

Bound


Y:

kubectl get ingress -n fequirogaa-dev


debe mostrar el Ingress de Metabase.

Finalmente debo poder acceder desde navegador a Metabase y visualizar el dataset Google Mobility almacenado en MySQL.

35. Orden completo del proyecto

Seguiremos exactamente esta secuencia:

1. Verificar kubectl/contexto
2. Verificar namespace existente
3. Inspeccionar cluster
4. Verificar Longhorn
5. Verificar Ingress NGINX
6. Crear estructura del repositorio
7. Crear Secret
8. Crear PVC
9. Verificar PVC Bound
10. Crear Service MySQL
11. Crear StatefulSet MySQL 8
12. Esperar MySQL Ready
13. Probar MySQL
14. Localizar google-mobility.sql.gz
15. Copiar dataset si fuera necesario
16. Importar dataset
17. Verificar tablas y registros
18. Crear Deployment Metabase
19. Verificar Metabase
20. Crear Service Metabase
21. Probar mediante port-forward
22. Configurar Metabase
23. Conectar Google Mobility
24. Crear Ingress
25. Verificar acceso externo
26. Crear consultas
27. Crear filtros
28. Crear gráficos
29. Crear dashboard
30. Probar persistencia MySQL
31. Revisar todos los recursos
32. Documentar el práctico
33. Preparar README/informe final


36. Primer paso que debes realizar ahora

No empieces creando YAML todavía.

Primero pedime o ejecutá únicamente comandos NO destructivos para conocer el estado real:

kubectl config current-context
kubectl config view --minify
kubectl get nodes -o wide
kubectl get pods -n fequirogaa-dev
kubectl get storageclass
kubectl get ingressclass
kubectl get pods -A | grep -Ei 'longhorn|ingress|rancher'


Analizá las salidas.

Después indicame cuál es el siguiente paso.

No avances suponiendo resultados.