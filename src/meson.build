binarygame_sources = [
  'main.vala',
  'window.vala',
]

binarygame_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
  meson.get_compiler('c').find_library('m', required : false),
]

gnome = import('gnome')

executable('binarygame', binarygame_sources,
  vala_args: '--target-glib=2.50',
  dependencies: binarygame_deps,
  install: true,
)
