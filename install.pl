#!/usr/bin/perl -w

use strict;
use warnings;
use Cwd;
use File::Copy;

system("clear");

my $vcenter, my $address, my $user, my $password, my $path_munin, my $path_dump, my $path_collector, my $path_install, my %hash;
my $dir = getcwd;
my $dirPlugins = $dir."/script/plugins/";

###établissement de la liste des plugins
opendir(my $REP, $dirPlugins);
my @plugins = grep {!/^\.\.?$/ } readdir($REP);
closedir($REP);

###formulaire
print "=== INSTALLATION DES PLUGINS ESX MUNIN ===\n";
print "== (CTRL+C si erreur de saisie) ==\n\n";
print "Indiquez l'emplacement du répertoire de configuration de Munin (par défaut : /etc/munin/)\n";
$path_munin = <>;
print "Indiquez le répertoire d'installation des plugins\n";
$path_install = <>;
print "Indiquez l'emplacement de sauvegarde des fichiers de données et de liens (chemin absolu du répertoire)\n";
$path_dump = <>;
print "Indiquez l'emplacement du script de récolte (chemin absolu du répertoire)\n"; 
$path_collector = <>;
print "Indiquez le nom du VCenter\n";
$vcenter = <>;
print "Indiquez l'adresse du VCenter (IP X.X.X.X)\n";
$address = <>;
print "Indiquez le nom d'utilisateur du VCenter\n";
$user = <>;
print "Indiquez le mot de passe de l'utilisateur du VCenter\n";
$password = <>;

###suppression des \n 
chomp($vcenter);
chomp($path_munin);
chomp($path_install);
chomp($path_dump);
chomp($path_collector);
chomp($address);
chomp($user);
chomp($password);

if ($path_munin eq '') { $path_munin = "/etc/munin/"; }

##ajout d'un / à la fin des chemins d'installation si manquant
if (substr($path_dump, -1) ne "/") { $path_dump .= "/"; } 
if (substr($path_collector, -1) ne "/") { $path_collector .= "/"; }
if (substr($path_install, -1) ne "/") { $path_install .= "/"; }
if (substr($path_munin, -1) ne "/") { $path_munin .= "/"; }

###vérification des droits en écriture pour les répertoires d'installtion
my $error = 0;
if (!-w $path_munin) {
  print "Manque de droits sur le répertoire $path_munin\n";
	$error = 1;
	}
if (!-w $path_dump) { 
	print "Manque de droits sur le répertoire $path_dump\n";
	$error = 1;
	}
if (!-w $path_collector) { 
        print "Manque de droits sur le répertoire $path_collector\n";
        $error = 1;
        }
if (!-w $path_install) { 
        print "Manque de droits sur le répertoire $path_install\n";
        $error = 1;
        }
if ($error == 1) { usage(); }

###copie des plugins vers le dossier d'installation
for (my $i = 0 ; $i <= (scalar(@plugins) - 1) ; $i++ ) {
	if (-e $path_install.$plugins[$i]) { unlink($path_install.$plugins[$i]); }
	copy($dirPlugins.$plugins[$i], $path_install.$plugins[$i]);
	chmod(0755, $path_install.$plugins[$i]);
	}

###copie du script de récolte vers son dossier d'installation
if (-e $path_collector."get_ressource_esx") { unlink($path_collector."get_ressource_esx"); }
copy($dir."/script/get_ressource_esx", $path_collector."get_ressource_esx");
chmod(0755, $path_collector."get_ressource_esx");

###création des liens symboliques des plugins dans le répertoire plugins de Munin
for (my $i = 0 ; $i <= (scalar(@plugins) - 1) ; $i++ ) {
        my $plugin_name = $plugins[$i];
        $plugin_name =~ s/^(esx_)/esx_$vcenter\_/;
	symlink($path_install.$plugins[$i], $path_munin."plugins/".$plugin_name);
        }

###création du fichier de configuration dans /etc/munin/plugin-conf.d/
open(CONF, ">".$path_munin."plugin-conf.d/munin-node-".$vcenter);
print CONF "[esx_*]\n";
print CONF "timeout 60\n\n";
print CONF "[esx_".$vcenter."*]\n";
print CONF "env.address ".$address."\n";
print CONF "env.user ".$user."\n";
print CONF "env.password ".$password."\n";
print CONF "env.path ".$path_dump."\n";
print CONF "env.collector ".$path_collector."\n";
print CONF "env.hostname ".$vcenter."\n";
close(CONF);
chmod(0755, $path_munin."plugin-conf.d/munin-node-".$vcenter);

###ajout de l'hôte virtuel dans munin.conf
open(CONF, ">>".$path_munin."munin.conf");
print CONF "\n[esx;".$vcenter."]\n";
print CONF "address 127.0.0.1\n";
print CONF "use_node_name no\n";
close(CONF);
chmod(0755, $path_munin."munin.conf");

###redémarrage du munin-node
`service munin-node restart`
or die "\n\n=== INSTALLATION REUSSIE ! (AVEC WARNINGS) ===\n\n"
."WARNING : Vous n'avez pas les droits suffisants pour redémarrer le munin-node, exécutez 'service munin-node restart' manuellement !\n\n"
."REMARQUE :\n"
."Par défaut, aucun filtre n'est mis en place sur les plugins.\n"
."Pour en rajouter, référez vous à la documentation (utilisation de variable d'environnement Munin et règles de nommage)\n\n";


###remarque
print "\n\n=== INSTALLATION REUSSIE AVEC SUCCES ! ===\n\n";
print "\n\nREMARQUE\n\n";
print "Par défaut, aucun filtre n'est mis en place sur les plugins.\n";
print "Pour en rajouter, référez vous à la documentation (utilisation de variable d'environnement Munin)\n\n";


sub usage {
	print "\n\n=== INSTALLATION ECHOUE ... ===\n\n";
	exit;
}
