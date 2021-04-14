{
    clamh_gate: {
      packages+: {
        gcc: '>=7.3.0',
        make: '>=3.83',
        # java: '==1.8.0',
        maven: '>=3.6.3'
      },
      downloads: {
        JAVA_HOME: {"name": "graalvm-ee-java8", "version": "20.2.0", "platformspecific": true}
      },
      # environment: {
      #   SBT_OPTS: "$GRADLE_OPTS" // until the CI sets it by default
      # },
      setup: [
        ["set-export", "PATH", "$JAVA_HOME/bin:$PATH"],
        ["set-export", "CLAMH_HOME", "$PWD"],
        ["set-export", "PATH", "$CLAMH_HOME/scripts:$PATH"],
        ["pwd"],
        ["ls"],
        # ["cd", "./clamh"],
        # ["source", "./clamh.rc"],
        ["make"],
        ["cd", "./test"]
      ],
      run: [
        ["./run_tests.sh"]
      ],
      targets: ["gate"],
      capabilities: ["linux", "amd64"],  # also consider "no_frequency_scaling"
      timelimit: "2:00:00",
      name: "gate-clamh"
    },

    builds: [
      self.clamh_gate
    ]
}
