# secure-shots
This is a coding assignment for UnifyID. Please open pics-security.xcworkspace file.


# Further Considerations
* Because of the time constraints, I chose directly to store the encrypted string of image data to keychain. A better implementation would be encrypting images with password (stored in keychain) and store the images to a document folder.
* Decoding part is not implemented, but it's not hard. Just extract the string data from keychain and show on the screen.
