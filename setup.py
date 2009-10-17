try:
    from setuptools import setup, find_packages
except ImportError:
    from ez_setup import use_setuptools
    use_setuptools()
    from setuptools import setup, find_packages

setup(
    name='Vertically Challenged',
    version='0.1.0',
    description='Using PostgreSQL Roles in your App',
    author='Aurynn Shaw, Commandprompt, Inc.',
    author_email='ashaw@commandprompt.com',
    url='https://projects.commandprompt.com/public/verticallychallenged/repo/dist',
    install_requires=[
        'Exceptable>=0.1.0'
    ],
    packages=find_packages(),
    test_suite='nose.collector',
    license='LGPL',
#    packages=['simpycity','test'],
    include_package_data=True,
    zip_safe=True,
    dependency_links=[
        "https://projects.commandprompt.com/public/exceptable/repo/dist/"
    ]
)
