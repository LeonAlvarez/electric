import React from 'react'
import { Alert, SafeAreaView } from 'react-native'
import { Button } from 'react-native-paper'
import EmailPasswordForm from '../components/EmailPasswordForm'
import { Link } from 'expo-router'
import { signIn } from '../components/AuthProvider'



export default function SignIn() {
  const signInWithEmail = async (email: string, password: string) => {
    const { error } = await signIn({
      email: email,
      password: password,
    })
    if (error) Alert.alert(error.message)
  }

  return (
    <SafeAreaView style={{ marginHorizontal: 16 }}>
      <EmailPasswordForm
        submitText="Sign in"
        onSubmit={signInWithEmail}
        />
      <Link href="/sign_up" replace asChild>
        <Button mode="text" style={{ marginTop: 12 }}>
          I don't have an account
        </Button>
      </Link>
    </SafeAreaView>
  )
}
