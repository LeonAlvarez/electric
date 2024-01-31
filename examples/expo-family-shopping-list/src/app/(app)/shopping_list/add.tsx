import React from 'react'
import { View } from 'react-native'
import ShoppingListEditor, { ShoppingListProperties } from '../../../components/ShoppingListEditor'
import { useElectric } from '../../../components/ElectricProvider'
import { genUUID } from 'electric-sql/util'
import { router } from 'expo-router';


export default function AddShoppingListItem () {
  const { db } = useElectric()!
  const onCreate = async (props: ShoppingListProperties) => {
    const newListId = genUUID()
    await db.shopping_list.create({
      data: {
        list_id: newListId,
        family_id: (await db.family.findFirst()).family_id,
        title: props.title ?? 'Untitled',
        updated_at: new Date(),
        created_at: new Date(),
      }
    })
    router.replace(`/shopping_list/${newListId}`)
  }

  return (
    <View>
      <ShoppingListEditor
        onSubmit={({title}) => onCreate({ title })}
        submitText="Create"
      />
    </View>
  )
}