import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'authentication.dart';

class LoginSignUpPage extends StatefulWidget {
  LoginSignUpPage({this.onSignedIn});

  final VoidCallback onSignedIn;

  @override
  State<StatefulWidget> createState() => new _LoginSignUpPageState();
}

enum FormMode { LOGIN, SIGNUP, GOOGLE }

class _LoginSignUpPageState extends State<LoginSignUpPage> {
  final _formKey = new GlobalKey<FormState>();

  String _email;
  String _password;
  String _errorMessage;

  // Initial form is login form
  FormMode _formMode = FormMode.LOGIN;
  bool _isIos;
  bool _isLoading = false;

  // Check if form is valid before perform login or signup
  bool _validateAndSave() {
    final form = _formKey.currentState;
    if (form.validate()) {
      form.save();
      return true;
    }
    return false;
  }

  // Perform login or signup
  _validateAndSubmit(FormMode formmode) async {
    _formMode = formmode;

    setState(() {
      _errorMessage = "";
      _isLoading = true;
    });

    try {
      FirebaseUser user;
      if (_formMode == FormMode.GOOGLE) {
        user = await authService.googleSignIn();
      } else if (_validateAndSave()) {
        if (_formMode == FormMode.LOGIN) {
          user = await authService.signInWithEmail(_email, _password);
        } else {
          user = await authService.signUp(_email, _password);
        }
        setState(() {
          _isLoading = false;
          // Navigator.pop(context);
        });

        // if (userId.length > 0 && userId != null) {
        //   widget.onSignedIn();
        // }
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
        if (_isIos) {
          _errorMessage = e.details;
        } else
          _errorMessage = e.message;
      });
    }
  }

  @override
  void initState() {
    _errorMessage = "";
    // _isLoading = false;
    super.initState();
    authService.loading.listen((state) => setState(() => _isLoading = state));
  }

  void _changeFormToSignUp() {
    // _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.SIGNUP;
    });
  }

  void _changeFormToLogin() {
    // _formKey.currentState.reset();
    _errorMessage = "";
    setState(() {
      _formMode = FormMode.LOGIN;
    });
  }

  @override
  Widget build(BuildContext context) {
    _isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return new Scaffold(
        // appBar: new AppBar(
        //   title: new Text('Flutter login demo'),
        // ),
        body: SafeArea(
      child: Stack(
        children: <Widget>[
          _showBody(),
          _showCircularProgress(),
        ],
      ),
    ));
  }

  Widget _showCircularProgress() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    return Container(
      height: 0.0,
      width: 0.0,
    );
  }

  Widget _showBody() {
    return new Container(
        padding: EdgeInsets.all(16.0),
        child: new Form(
          key: _formKey,
          child: new ListView(
            shrinkWrap: true,
            children: <Widget>[
              _showLogo(),
              _showEmailInput(),
              _showPasswordInput(),
              _showPrimaryButton(),
              _showSecondaryButton(),
              _showErrorMessage(),
              _showGoogleButton(),
            ],
          ),
        ));
  }

  Widget _showErrorMessage() {
    if (_errorMessage.length > 0 && _errorMessage != null) {
      return new Text(
        _errorMessage,
        style: TextStyle(
            fontSize: 13.0,
            color: Colors.red,
            height: 1.0,
            fontWeight: FontWeight.w300),
      );
    } else {
      return new Container(
        height: 0.0,
      );
    }
  }

  Widget _showLogo() {
    return new Hero(
      tag: 'hero',
      child: Padding(
        padding: EdgeInsets.fromLTRB(0.0, 100.0, 0.0, 0.0),
        child: CircleAvatar(
          backgroundColor: Colors.transparent,
          radius: 24.0,
          child: Image.asset('assets/icon.png'),
        ),
      ),
    );
  }

  Widget _showEmailInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 40.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        keyboardType: TextInputType.emailAddress,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Email',
            icon: new Icon(
              Icons.mail,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Email can\'t be empty' : null,
        onSaved: (value) => _email = value,
      ),
    );
  }

  Widget _showPasswordInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0.0, 15.0, 0.0, 0.0),
      child: new TextFormField(
        maxLines: 1,
        obscureText: true,
        autofocus: false,
        decoration: new InputDecoration(
            hintText: 'Password',
            icon: new Icon(
              Icons.lock,
              color: Colors.grey,
            )),
        validator: (value) => value.isEmpty ? 'Password can\'t be empty' : null,
        onSaved: (value) => _password = value,
      ),
    );
  }

  final _biggerText = TextStyle(fontSize: 18.0, fontWeight: FontWeight.w300);

  Widget _showSecondaryButton() {
    return new FlatButton(
      child: _formMode == FormMode.LOGIN
          ? new Text('Create an account', style: _biggerText)
          : new Text('Have an account? Sign in', style: _biggerText),
      onPressed: _formMode == FormMode.LOGIN
          ? _changeFormToSignUp
          : _changeFormToLogin,
    );
  }

  Widget _showPrimaryButton() {
    return new Padding(
        padding: EdgeInsets.fromLTRB(0.0, 45.0, 0.0, 0.0),
        child: SizedBox(
          height: 50.0,
          child: new RaisedButton(
            // elevation: 5.0,
            // shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
            child: Text(
                _formMode == FormMode.LOGIN ? 'Login' : 'Create account',
                style: _biggerText),
            onPressed: () => _validateAndSubmit(_formMode),
            // color: Colors.pink
          ),
        ));
  }

  Widget _showGoogleButton() {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 25.0, 0.0, 0.0),
        child: Column(
          children: <Widget>[
            Text("OR"),
            Padding(
              padding: EdgeInsets.fromLTRB(0.0, 25.0, 0.0, 0.0),
              child: SizedBox(
                height: 50.0,
                width: double.infinity,
                child: RaisedButton(
                    child: Text('Sign in with Google', style: _biggerText.copyWith(color: Colors.white)),
                    onPressed: () => _validateAndSubmit(FormMode.GOOGLE),
                    color: Colors.red),
              ),
            ),
          ],
        ));
  }
}
