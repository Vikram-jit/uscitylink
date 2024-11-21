class FileModel {
  String? fieldname;
  String? originalname;
  String? encoding;
  String? mimetype;
  int? size;
  String? bucket;
  String? key;
  String? acl;
  String? contentType;
  String? location;

  FileModel({
    this.fieldname,
    this.originalname,
    this.encoding,
    this.mimetype,
    this.size,
    this.bucket,
    this.key,
    this.acl,
    this.contentType,
    this.location,
  });

  FileModel.fromJson(Map<String, dynamic> json) {
    fieldname = json['fieldname'];
    originalname = json['originalname'];
    encoding = json['encoding'];
    mimetype = json['mimetype'];
    size = json['size'];
    bucket = json['bucket'];
    key = json['key'];
    acl = json['acl'];
    contentType = json['contentType'];

    location = json['location'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['fieldname'] = fieldname;
    data['originalname'] = originalname;
    data['encoding'] = encoding;
    data['mimetype'] = mimetype;
    data['size'] = size;
    data['bucket'] = bucket;
    data['key'] = key;
    data['acl'] = acl;
    data['contentType'] = contentType;

    data['location'] = location;

    return data;
  }
}
