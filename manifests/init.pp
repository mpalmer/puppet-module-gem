# Install a gem.
#
# This type is an alternative to using the built-in `package` type, for those
# times when you need a bit more (read: *any*) flexibility in how your gem
# gets installed.
#
# Attributes:
#
#  * `package` (optional; string; default `undef`)
#
#     If defined, this value will be used as the gem name.  Otherwise, the
#     resource title will be used.  This allows you to request the same gem
#     be installed multiple times in different manifests, by simply
#     providing a unique resource name each time.
#
#  * `version` (optional; string; default `undef`)
#
#     If defined, then a version specifier will be added to the installation
#     to limit which version may be installed.  This string can either be a
#     specific version (eg `"1.2.3"`), or some sort of comparator version,
#     such as `">= 1.2.3"` or `"~> 1.2"`.
#
#  * `source` (optional; string; default `undef`)
#
#     If defined, the value of this attribute will be used as an additional
#     source for gems (in addition to the default(s) defined on the system).
#     Quite handy if you're running your own local gem server (and who
#     doesn't these days?).
#
#  * `chruby` (optional; string; default `undef`)
#
#     Install the gem using an alternative Ruby installation.  If this value
#     is defined, then the gem installation will be run using `chruby-exec`,
#     with this value as the Ruby installation specifier.
#
#  * `user` (optional; string; default `undef`)
#
#     If defined, then run the installation as that user, as well as
#     specifying `--user-install` to the `gem install` command.  This will
#     cause the gem(s) to be installed in the user's own gem tree (typically
#     somewhere under `~/.gem`) rather than in the system-wide gem tree.
#
#  * `docs` (optional; boolean; default `false`)
#
#     If `true`, then ri/rdoc documentation will be generated for the gem(s)
#     installed by this command.  Since it's rare you want rdoc/ri on a
#     Puppet-managed machine, this defaults to `false`.
#
define gem(
		$package = undef,
		$version = undef,
		$source  = undef,
		$chruby  = undef,
		$user    = undef,
		$docs    = false,
) {
	if $chruby {
		$q_chruby = shellquote($chruby)
		$chruby_prefix = "chruby-exec ${q_chruby} -- "
	}

	if $package {
		$gem_name = shellquote($package)
	} else {
		$gem_name = shellquote($name)
	}

	if $version {
		$q_version = shellquote($version)
		$version_opt = " --version ${q_version}"
	}

	if $source {
		$q_source = shellquote($source)
		$source_opt = " --source ${q_source}"
	}

	if $user {
		$user_opt = " --user-install"
	}

	if $docs {
		$docs_opt = " --rdoc --ri"
	} else {
		$docs_opt = " --no-rdoc --no-ri"
	}

	if $user {
		$_homedir = homedir($user)
		if $_homedir == undef {
			# User doesn't exist yet; presumably they'll get created before the
			# gem gets installed, but since we need a HOME now, we'll make an
			# assumption and hope for the best
			$homedir = "/home/${user}"
		} else {
			$homedir = $_homedir
		}
	} else {
		$homedir = homedir("root")
	}

	exec { "gem->${name}":
		path        => "/usr/local/bin:/usr/bin:/bin",
		command     => "${chruby_prefix}gem install ${gem_name}${version_opt}${source_opt}${user_opt}${docs_opt}",
		unless      => "${chruby_prefix}gem query --installed -n '^${gem_name}\$'${version_opt}",
		environment => "HOME='${homedir}'",
		user        => $user ? {
			undef => "root",
			default => $user
		},
	}
}
