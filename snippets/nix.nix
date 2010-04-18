snippet derivation
		<++> = stdenv.mkDerivation {
			name = "<++>";
			buildInputs = [];
			src = <template again>
			meta = <+template again+>
		}
snippet fetchsvn
	fetchsvn { rev = 7132; 
  		url=https://svn.qgis.org/repos/qgis/trunk/qgis; md5="e3b3e69ba0baf78fed2e4b12e5bf9c2e"; 
	};
snippet job_new
	{pkgs, config, ...}:
	
	###### interface
	let
		inherit (pkgs.lib) mkOption mkIf;
	
		options = {
			services = {
				pulseaudio = {
					enable = mkOption {
						default = false;
						description = ''
							Whether to enable the PulseAudio system-wide audio server.
							Note that the documentation recommends running PulseAudio
							daemons per-user rather than system-wide on desktop machines.
						'';
					};
	
					logLevel = mkOption {
						default = "notice";
						example = "debug";
						description = ''
							A string denoting the log level: one of
							<literal>error</literal>, <literal>warn</literal>,
							<literal>notice</literal>, <literal>info</literal>,
							or <literal>debug</literal>.
						'';
					};
				};
			};
		};
	in
	
	###### implementation
	
	mkIf config.services.pulseaudio.enable {
		require = [
			options
		];
	
		environment = {
	
			extraPackages =
				pkgs.lib.optional
					(!config.environment.cleanStart)
					pkgs.pulseaudio;
	
			etc = [
				# The system-wide crontab.
				{ source = systemCronJobsFile;
					target = "crontab";
					mode = "0600"; # Cron requires this.
				}
			];
	
		};
	
		users = {
			extraUsers = [
				{ name = "pulse";
					inherit uid;
					group = "pulse";
					description = "PulseAudio system-wide daemon";
					home = "/var/run/pulse";
				}
			];
	
			extraGroups = [
				{ name = "pulse";
					inherit gid;
				}
			];
		};
	
		services = {
			extraJobs = [{
				name = "pulseaudio";
	
				job = ''
					description "PulseAudio system-wide server"
	
					start on startup
					stop on shutdown
	
					start script
						test -d /var/run/pulse ||			\
						( mkdir -p --mode 755 /var/run/pulse &&	\
							chown pulse:pulse /var/run/pulse )
					end script
	
					respawn ${pkgs.pulseaudio}/bin/pulseaudio								\
						--system --daemonize																	\
						--log-level="${config.services.pulseaudio.logLevel}"
				'';
			}];
		};
	}
snippet meta
	meta = {
		description = "${1}";
		homepage = ${2};
		license = ${3};
		maintainers = [stdenv.lib.maintainers.`exists('g:nix_maintainer') ? g:nix_maintainer : 'YOURNAME'`;
		platforms = stdenv.lib.platforms.linux;
	};
snippet src
	src = fetchurl {
		url = ${1};
		sha256 = "${2}";
	};
snippet t_simple
	{stdenv, fetchurl${1:}}:

	stdenv.mkDerivation {
		name = "";
	
		src = fetchurl {
			url = ;
			sha256 = "";
		};
	
		buildInputs = [];
	
		meta = {
			description = "<++>";
			homepage = <++>;
			license = <++>;
			maintainers = [stdenv.lib.maintainers.`exists('g:nix_maintainer') ? g:nix_maintainer : 'YOURNAME'`;
			platforms = stdenv.lib.platforms.linux;
		};
	}
snippet b
	builtins.
snippet nix_repository_manager_svn
	# REGION AUTO UPDATE: { name="?"; type="svn"; url=""; [ groups = "group1 group2"; ]; }
	# END
snippet i
	inherit stdenv fetchurl ${1};
