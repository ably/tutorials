function train(props) {
  const lines = [
    { name: "metropolitan", value: "metropolitan" },
    { name: "central", value: "central" },
    { name: "waterloo-city", value: "waterloo-city" },
    { name: "jubilee", value: "jubilee" },
    { name: "victoria", value: "victoria" },
    { name: "bakerloo", value: "bakerloo" },
    { name: "hammersmith-city", value: "hammersmith-city" },
    { name: "circle", value: "circle" },
    { name: "district", value: "district" },
    { name: "piccadilly", value: "piccadilly" },
    { name: "northern", value: "northern" }
  ]; // Possible Lines
  // Through the props we can access the settingsStorage and get value for any item which
  // was set in the companion with data
  return (
    <Page>
      <Section
        title={
          <Text bold align="center">
            Station and Line Settings
          </Text>
        }
      >
        <Select label={`Line`} settingsKey="line" options={lines} />
        {/* Getting the possible stations depending on the line selected by the user, 
        through the settingsStorage set in the companion */}
        {props.settingsStorage.getItem("stationspossible") && (
          <TextInput
            title="Select Station Name"
            label="Station Name"
            placeholder="Search station"
            settingsKey="origin" // Used to read the selected value in companion
            action="Add Item"
            onAutocomplete={value => {
              const autoValues = JSON.parse(
                props.settingsStorage.getItem("stationspossible")
              ).values;
              return autoValues.filter(option =>
                option.name.toLowerCase().startsWith(value.toLowerCase())
              );
            }}
          />
        )}
        {/* Getting possible towards depending on the line & station selected by the user, 
        through the settingsStorage set in the companion */}
        {props.settingsStorage.getItem("via") && (
          <TextInput
            title="Select Station Name"
            label="Towards"
            placeholder="Search station"
            settingsKey="towards" // Used to read the selected value in companion
            action="Add Item"
            onAutocomplete={value => {
              const autoValues = JSON.parse(
                props.settingsStorage.getItem("via")
              ).values;
              return autoValues.filter(option =>
                option.name.toLowerCase().startsWith(value.toLowerCase())
              );
            }}
          />
        )}
      </Section>
    </Page>
  );
}

registerSettingsPage(train);