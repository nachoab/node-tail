Package.describe({
  summary: "Tail file for Meteor"
});


Npm.depends({
  "coffee-script": "1.6.2"
});


Package.on_use(function (api) {
  api.export("Tail");
  api.add_files("tail.coffee", 'server');
});