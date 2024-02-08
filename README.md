# MySQL and Wordpress

This Dockerfile builds an image that contains a mariadb database, a wordpress installation, and a phpmyadmin interface for managing the database.

## Prerequisites

To build this image, you will need the following:

docker

To build the image, run the following command:

``` bash 
docker build -t wordpress-and-mysql .
```
To run the image, run the following command:

``` bash 
docker run -d -p 80:80 -p 3306:3306 --name wordpress-and-mysql wordpress-and-mysql
```  
[Prebuild image wordpress-and-mysql is available at docker hub](https://hub.docker.com/repository/docker/rnawaz02/wordpress-and-mysql/general). You can directly pull the image from docker hub and run the image using the following command:

``` bash
 docker run -d -p 80:80 -p 3306:3306 --name rnawaz02/wordpress-and-mysql docker pull rnawaz02/wordpress-and-mysql
 ```
This will start the mariadb database, the apache2 web server, and the phpmyadmin interface. You can then access the wordpress installation by going to http://localhost/ and the phpmyadmin interface by going to http://localhost/phpmyadmin.

## Configuration

The following environment variables can be used to configure the image: Default values will be used if not specified with docker run command.

* MARIADB_DATABASE=db The name of the mariadb database.
* MARIADB_USER=user The username for the mariadb database.
* MARIADB_PASSWORD=Welcome1 The password for the mariadb database.
* MARIADB_ROOT_PASSWORD=Welcome1 The password for the mariadb root user.
  
The follwoing command can be used to set the environment variables, volumes and ports: Please modify the path according to your local path.

``` bash
docker run -p 80:80 -p 443:443 -p 3306:3306 -e MARIADB_DATABASE=db -e MARIADB_USER=user -e MARIADB_PASSWORD=Welcome1 -e MARIADB_ROOT_PASSWORD=Welcome1 -v C:\sandbox\code\datadir:/srv -v C:\sandbox\code\db:/var/lib/mysql rnawaz02/wordpress-and-mysql
```
We can mount two volumes. 

* /var/lib/mysql to store the mariadb database
* /srv to store the wordpress installation, phpmyadmin configuration and wordpress configurations.

Files will be created if mounts are empty otherwise existing files will be used by the container.

Troubleshooting

If you encounter any problems with the image, please refer to the following resources:

[Docker documentation](https://docs.docker.com/)

[mariadb documentation](https://mariadb.com/kb/en/)

[wordpress documentation](https://wordpress.org/documentation/)

[phpmyadmin documentation](https://www.phpmyadmin.net/docs/)

## License

This image is licensed under the [Apache License 2](https://www.apache.org/licenses/LICENSE-2.0).

